require "rails_helper"

RSpec.describe Payments::ProcessWebhookEvent do
  describe "#call" do
    it "returns a success result placeholder for now" do
      payment_webhook_event = create(:payment_webhook_event)

      result = described_class.new(payment_webhook_event: payment_webhook_event).call

      expect(result).to be_success
      expect(result.payment_webhook_event).to eq(payment_webhook_event)
    end
  end
end
