require "rails_helper"

RSpec.describe Payments::Webhooks::YookassaProcessor do
  describe "#call" do
    let(:user) { create(:user) }
    let!(:financial_account) { create(:financial_account, user: user, currency: "USD", available_amount_cents: 0, held_amount_cents: 0) }

    it "finalizes successful payments" do
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

      expect(result).to eq(payment.reload)
      expect(payment).to be_succeeded
      expect(financial_account.reload.available_amount_cents).to eq(7_500)
    end

    it "marks canceled payments as canceled" do
      payment = create(:payment, user: user, financial_account: financial_account, provider: :yookassa, provider_payment_id: "yo_cancel", amount_cents: 7_500, currency: "USD", status: :pending)
      payment_webhook_event = create(
        :payment_webhook_event,
        provider: :yookassa,
        event_type: "payment.canceled",
        payload: {
          "type" => "notification",
          "event" => "payment.canceled",
          "object" => {
            "id" => "yo_cancel",
            "metadata" => { "payment_id" => payment.id.to_s }
          }
        }
      )

      result = described_class.new(payment_webhook_event: payment_webhook_event).call

      expect(result).to eq(payment.reload)
      expect(payment).to be_canceled
    end
  end
end
