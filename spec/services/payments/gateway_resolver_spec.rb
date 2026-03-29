require "rails_helper"

RSpec.describe Payments::GatewayResolver do
  describe ".call" do
    it "returns the stripe strategy" do
      expect(described_class.call(provider: :stripe)).to be_a(Payments::Gateway::StripeStrategy)
    end

    it "returns the yookassa strategy" do
      expect(described_class.call(provider: "yookassa")).to be_a(Payments::Gateway::YookassaStrategy)
    end

    it "raises for an unknown provider" do
      expect {
        described_class.call(provider: :paypal)
      }.to raise_error(ArgumentError, "Unsupported payment provider: paypal")
    end
  end
end
