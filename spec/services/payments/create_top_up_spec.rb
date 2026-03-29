require "rails_helper"

RSpec.describe Payments::CreateTopUp do
  let(:user) { create(:user) }
  let!(:financial_account) { create(:financial_account, user: user, currency: "USD") }
  let(:success_url) { "https://example.com/top_ups/success" }
  let(:cancel_url) { "https://example.com/top_ups/cancel" }
  let(:gateway_response) do
    Payments::Gateway::Base::Response.new(
      provider_payment_id: "provider-payment-123",
      provider_checkout_session_id: "provider-session-123",
      confirmation_url: "https://provider.test/checkout",
      raw_response: { "id" => "provider-payment-123" }
    )
  end
  let(:gateway) { instance_double(Payments::Gateway::StripeStrategy, create_top_up: gateway_response) }

  describe "#call" do
    it "creates a pending payment and persists the redirect data" do
      allow(Payments::GatewayResolver).to receive(:call).with(provider: "stripe").and_return(gateway)

      result = described_class.new(
        user: user,
        provider: "stripe",
        amount: "123.45",
        success_url: success_url,
        cancel_url: cancel_url
      ).call

      expect(result).to be_success
      expect(result.redirect_url).to eq("https://provider.test/checkout")

      payment = result.payment.reload
      expect(payment).to be_pending
      expect(payment.amount_cents).to eq(12_345)
      expect(payment.currency).to eq("USD")
      expect(payment.provider_payment_id).to eq("provider-payment-123")
      expect(payment.provider_checkout_session_id).to eq("provider-session-123")
      expect(payment.confirmation_url).to eq("https://provider.test/checkout")
      expect(payment.return_url).to eq(success_url)
      expect(payment.metadata).to include("cancel_url" => cancel_url)
    end

    it "rounds to the nearest cent using half up" do
      allow(Payments::GatewayResolver).to receive(:call).with(provider: "stripe").and_return(gateway)

      result = described_class.new(
        user: user,
        provider: "stripe",
        amount: "10.005",
        success_url: success_url,
        cancel_url: cancel_url
      ).call

      expect(result.payment.amount_cents).to eq(1_001)
    end

    it "fails for an invalid provider without creating a payment" do
      result = described_class.new(
        user: user,
        provider: "paypal",
        amount: "50.00",
        success_url: success_url,
        cancel_url: cancel_url
      ).call

      expect(result).not_to be_success
      expect(result.error).to eq("Unsupported payment provider")
      expect(Payment.count).to eq(0)
    end

    it "fails for an invalid amount without creating a payment" do
      result = described_class.new(
        user: user,
        provider: "stripe",
        amount: "0",
        success_url: success_url,
        cancel_url: cancel_url
      ).call

      expect(result).not_to be_success
      expect(result.error).to eq("Amount must be greater than 0")
      expect(Payment.count).to eq(0)
    end

    it "marks the payment as failed when gateway creation fails" do
      allow(Payments::GatewayResolver).to receive(:call).with(provider: "stripe").and_return(gateway)
      allow(gateway).to receive(:create_top_up).and_raise(StandardError, "Gateway unavailable")

      result = described_class.new(
        user: user,
        provider: "stripe",
        amount: "25.00",
        success_url: success_url,
        cancel_url: cancel_url
      ).call

      expect(result).not_to be_success
      expect(result.error).to eq("Gateway unavailable")

      payment = Payment.find_by!(user: user)
      expect(payment).to be_failed
      expect(payment.failure_reason).to eq("Gateway unavailable")
    end
  end
end
