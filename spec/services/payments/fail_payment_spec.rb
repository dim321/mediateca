require "rails_helper"

RSpec.describe Payments::FailPayment do
  let(:payment) { create(:payment, status: :pending) }
  let(:payload) { { "event" => "payment.canceled" } }

  describe "#call" do
    it "marks the payment as failed" do
      result = described_class.new(payment: payment, payload: payload, status: :failed).call

      expect(result).to be_success
      expect(payment.reload).to be_failed
      expect(payment.failed_at).to be_present
    end

    it "is idempotent for the same terminal status" do
      described_class.new(payment: payment, payload: payload, status: :failed).call
      result = described_class.new(payment: payment, payload: payload, status: :failed).call

      expect(result).to be_success
      expect(result).to be_idempotent
    end
  end
end
