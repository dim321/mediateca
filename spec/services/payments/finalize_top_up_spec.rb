require "rails_helper"

RSpec.describe Payments::FinalizeTopUp do
  let(:user) { create(:user) }
  let!(:financial_account) { create(:financial_account, user: user, currency: "USD", available_amount_cents: 10_000, held_amount_cents: 0) }
  let(:payment) { create(:payment, user: user, financial_account: financial_account, provider: :stripe, amount_cents: 12_345, currency: "USD", status: :pending) }
  let(:payload) { { "id" => "evt_123", "type" => "checkout.session.completed" } }

  describe "#call" do
    it "marks the payment as succeeded and credits the wallet" do
      result = described_class.new(payment: payment, payload: payload).call

      expect(result).to be_success
      expect(payment.reload).to be_succeeded
      expect(payment.paid_at).to be_present
      expect(financial_account.reload.available_amount_cents).to eq(22_345)
      expect(result.ledger_entry).to be_deposit_settled
    end

    it "is idempotent on repeated processing" do
      first_result = described_class.new(payment: payment, payload: payload).call
      second_result = described_class.new(payment: payment, payload: payload).call

      expect(first_result).to be_success
      expect(second_result).to be_success
      expect(second_result).to be_idempotent
      expect(financial_account.reload.available_amount_cents).to eq(22_345)
      expect(payment.ledger_entries.where(idempotency_key: "payment:#{payment.id}:settled").count).to eq(1)
    end
  end
end
