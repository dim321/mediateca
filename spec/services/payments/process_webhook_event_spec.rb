require "rails_helper"

RSpec.describe Payments::ProcessWebhookEvent do
  describe "#call" do
    let(:user) { create(:user) }
    let!(:financial_account) { create(:financial_account, user: user, currency: "USD", available_amount_cents: 0, held_amount_cents: 0) }

    it "finalizes a stripe checkout.session.completed event" do
      payment = create(:payment, user: user, financial_account: financial_account, provider: :stripe, provider_checkout_session_id: "cs_test_123", amount_cents: 5_000, currency: "USD", status: :pending)
      payment_webhook_event = create(
        :payment_webhook_event,
        provider: :stripe,
        event_type: "checkout.session.completed",
        payload: {
          "id" => "evt_123",
          "type" => "checkout.session.completed",
          "data" => {
            "object" => {
              "id" => "cs_test_123",
              "payment_intent" => "pi_123",
              "metadata" => { "payment_id" => payment.id.to_s }
            }
          }
        }
      )

      result = described_class.new(payment_webhook_event: payment_webhook_event).call

      expect(result).to be_success
      expect(result.payment).to eq(payment.reload)
      expect(payment).to be_succeeded
      expect(payment_webhook_event.reload.processed_at).to be_present
      expect(financial_account.reload.available_amount_cents).to eq(5_000)
    end

    it "finalizes a yookassa payment.succeeded event" do
      payment = create(:payment, user: user, financial_account: financial_account, provider: :yookassa, provider_payment_id: "yo_123", amount_cents: 7_500, currency: "USD", status: :pending)
      payment_webhook_event = create(
        :payment_webhook_event,
        provider: :yookassa,
        event_type: "payment.succeeded",
        payload: {
          "type" => "notification",
          "event" => "payment.succeeded",
          "object" => {
            "id" => "yo_123",
            "metadata" => { "payment_id" => payment.id.to_s }
          }
        }
      )

      result = described_class.new(payment_webhook_event: payment_webhook_event).call

      expect(result).to be_success
      expect(payment.reload).to be_succeeded
      expect(payment_webhook_event.reload.processed_at).to be_present
      expect(financial_account.reload.available_amount_cents).to eq(7_500)
    end

    it "marks failed stripe payment events as failed" do
      payment = create(:payment, user: user, financial_account: financial_account, provider: :stripe, provider_checkout_session_id: "cs_expired", amount_cents: 5_000, currency: "USD", status: :pending)
      payment_webhook_event = create(
        :payment_webhook_event,
        provider: :stripe,
        event_type: "checkout.session.expired",
        payload: {
          "id" => "evt_failed",
          "type" => "checkout.session.expired",
          "data" => {
            "object" => {
              "id" => "cs_expired",
              "payment_intent" => "pi_failed",
              "metadata" => { "payment_id" => payment.id.to_s }
            }
          }
        }
      )

      result = described_class.new(payment_webhook_event: payment_webhook_event).call

      expect(result).to be_success
      expect(payment.reload).to be_failed
      expect(payment_webhook_event.reload.processed_at).to be_present
    end

    it "is idempotent when the webhook event was already processed" do
      payment_webhook_event = create(:payment_webhook_event, processed_at: Time.current)

      result = described_class.new(payment_webhook_event: payment_webhook_event).call

      expect(result).to be_success
      expect(result).to be_ignored
    end
  end
end
