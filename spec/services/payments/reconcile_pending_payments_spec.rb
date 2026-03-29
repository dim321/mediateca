require "rails_helper"

RSpec.describe Payments::ReconcilePendingPayments do
  describe "#call" do
    let(:user) { create(:user) }
    let!(:financial_account) { create(:financial_account, user: user, currency: "USD", available_amount_cents: 0, held_amount_cents: 0) }

    it "finalizes stale Stripe payments that succeeded remotely" do
      payment = create(:payment, user: user, financial_account: financial_account, provider: :stripe, status: :pending, amount_cents: 5_000, currency: "USD", created_at: 10.minutes.ago)
      fetcher = instance_double(Payments::Reconciliation::StripeFetcher)

      allow(Payments::Reconciliation::StripeFetcher).to receive(:new).and_return(fetcher)
      allow(fetcher).to receive(:fetch).with(payment).and_return(
        Payments::Reconciliation::BaseFetcher::Response.new(
          remote_status: :succeeded,
          payload: { "id" => "pi_success" },
          failure_reason: nil
        )
      )

      result = described_class.new.call

      expect(result.scanned_count).to eq(1)
      expect(result.succeeded_count).to eq(1)
      expect(payment.reload).to be_succeeded
      expect(financial_account.reload.available_amount_cents).to eq(5_000)
    end

    it "fails stale YooKassa payments that were canceled remotely" do
      payment = create(:payment, user: user, financial_account: financial_account, provider: :yookassa, provider_payment_id: "yo_cancel", status: :pending, amount_cents: 7_500, currency: "USD", created_at: 10.minutes.ago)
      fetcher = instance_double(Payments::Reconciliation::YookassaFetcher)

      allow(Payments::Reconciliation::YookassaFetcher).to receive(:new).and_return(fetcher)
      allow(fetcher).to receive(:fetch).with(payment).and_return(
        Payments::Reconciliation::BaseFetcher::Response.new(
          remote_status: :canceled,
          payload: { "id" => "yo_cancel", "status" => "canceled" },
          failure_reason: "expired_on_confirmation"
        )
      )

      result = described_class.new.call

      expect(result.scanned_count).to eq(1)
      expect(result.failed_count).to eq(1)
      expect(payment.reload).to be_canceled
      expect(payment.failure_reason).to eq("expired_on_confirmation")
    end

    it "updates non-terminal payments without finalizing them" do
      payment = create(:payment, user: user, financial_account: financial_account, provider: :stripe, status: :pending, amount_cents: 5_000, currency: "USD", created_at: 10.minutes.ago)
      fetcher = instance_double(Payments::Reconciliation::StripeFetcher)

      allow(Payments::Reconciliation::StripeFetcher).to receive(:new).and_return(fetcher)
      allow(fetcher).to receive(:fetch).with(payment).and_return(
        Payments::Reconciliation::BaseFetcher::Response.new(
          remote_status: :processing,
          payload: { "id" => "pi_processing", "status" => "processing" },
          failure_reason: nil
        )
      )

      result = described_class.new.call

      expect(result.updated_count).to eq(1)
      expect(payment.reload).to be_processing
      expect(financial_account.reload.available_amount_cents).to eq(0)
    end

    it "does not reprocess already terminal payments" do
      payment = create(:payment, user: user, financial_account: financial_account, provider: :stripe, status: :succeeded, amount_cents: 5_000, currency: "USD", created_at: 10.minutes.ago)

      result = described_class.new.call

      expect(result.scanned_count).to eq(0)
      expect(payment.reload).to be_succeeded
    end

    it "isolates provider errors and continues the batch" do
      stripe_payment = create(:payment, user: user, financial_account: financial_account, provider: :stripe, status: :pending, amount_cents: 5_000, currency: "USD", created_at: 10.minutes.ago)
      yookassa_payment = create(:payment, user: user, financial_account: financial_account, provider: :yookassa, provider_payment_id: "yo_success", status: :pending, amount_cents: 3_000, currency: "USD", created_at: 10.minutes.ago)

      stripe_fetcher = instance_double(Payments::Reconciliation::StripeFetcher)
      yookassa_fetcher = instance_double(Payments::Reconciliation::YookassaFetcher)

      allow(Payments::Reconciliation::StripeFetcher).to receive(:new).and_return(stripe_fetcher)
      allow(Payments::Reconciliation::YookassaFetcher).to receive(:new).and_return(yookassa_fetcher)
      allow(stripe_fetcher).to receive(:fetch).with(stripe_payment).and_raise(Faraday::TimeoutError, "timeout")
      allow(yookassa_fetcher).to receive(:fetch).with(yookassa_payment).and_return(
        Payments::Reconciliation::BaseFetcher::Response.new(
          remote_status: :succeeded,
          payload: { "id" => "yo_success", "status" => "succeeded" },
          failure_reason: nil
        )
      )

      result = described_class.new.call

      expect(result.scanned_count).to eq(2)
      expect(result.error_count).to eq(1)
      expect(result.succeeded_count).to eq(1)
      expect(yookassa_payment.reload).to be_succeeded
      expect(stripe_payment.reload).to be_pending
    end
  end
end
