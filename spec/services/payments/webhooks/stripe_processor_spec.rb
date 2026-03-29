require "rails_helper"

RSpec.describe Payments::Webhooks::StripeProcessor do
  describe "#call" do
    let(:user) { create(:user) }
    let!(:financial_account) { create(:financial_account, user: user, currency: "USD", available_amount_cents: 0, held_amount_cents: 0) }

    it "finalizes completed checkout sessions" do
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

      expect(result).to eq(payment.reload)
      expect(payment).to be_succeeded
      expect(financial_account.reload.available_amount_cents).to eq(5_000)
    end

    it "marks expired checkout sessions as failed" do
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

      expect(result).to eq(payment.reload)
      expect(payment).to be_failed
    end
  end
end
