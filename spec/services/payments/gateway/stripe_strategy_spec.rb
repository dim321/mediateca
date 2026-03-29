require "rails_helper"

RSpec.describe Payments::Gateway::StripeStrategy do
  let(:payment) do
    create(
      :payment,
      provider: :stripe,
      amount_cents: 12_345,
      currency: "USD",
      metadata: { source: "wallet", order_id: 42 }
    )
  end
  let(:success_url) { "https://example.com/top_ups/success" }
  let(:cancel_url) { "https://example.com/top_ups/cancel" }

  describe "#create_top_up" do
    it "creates a checkout session with metadata and idempotency" do
      session = double(
        id: "cs_test_123",
        payment_intent: "pi_test_123",
        url: "https://checkout.stripe.test/session",
        to_hash: { "id" => "cs_test_123" }
      )

      expect(Stripe::Checkout::Session).to receive(:create).with(
        hash_including(
          mode: "payment",
          success_url: success_url,
          cancel_url: cancel_url,
          client_reference_id: payment.user_id.to_s,
          metadata: hash_including(
            "payment_id" => payment.id.to_s,
            "user_id" => payment.user_id.to_s,
            "operation_type" => "top_up",
            "source" => "wallet",
            "order_id" => "42"
          ),
          payment_intent_data: hash_including(
            metadata: hash_including("payment_id" => payment.id.to_s)
          ),
          line_items: [
            hash_including(
              quantity: 1,
              price_data: hash_including(
                currency: "usd",
                unit_amount: 12_345,
                product_data: hash_including(
                  name: "Wallet top-up ##{payment.id}",
                  metadata: hash_including("payment_id" => payment.id.to_s)
                )
              )
            )
          ]
        ),
        hash_including(idempotency_key: payment.idempotency_key)
      ).and_return(session)

      result = described_class.new.create_top_up(
        payment: payment,
        success_url: success_url,
        cancel_url: cancel_url
      )

      expect(result.provider_payment_id).to eq("pi_test_123")
      expect(result.provider_checkout_session_id).to eq("cs_test_123")
      expect(result.confirmation_url).to eq("https://checkout.stripe.test/session")
      expect(result.raw_response).to eq({ "id" => "cs_test_123" })
    end
  end
end
