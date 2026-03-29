require "rails_helper"

RSpec.describe Payments::Gateway::YookassaStrategy do
  let(:payment) do
    create(
      :payment,
      provider: :yookassa,
      amount_cents: 12_345,
      currency: "GEL",
      metadata: { source: "wallet", order_id: 42 }
    )
  end
  let(:return_url) { "https://example.com/top_ups/return" }
  let(:api_base_url) { "https://api.yookassa.test/v3" }

  describe "#create_top_up" do
    it "posts a redirect payment with metadata and idempotency" do
      allow(YookassaConfig).to receive(:api_base_url!).and_return(api_base_url)
      allow(YookassaConfig).to receive(:shop_id!).and_return("shop-test")
      allow(YookassaConfig).to receive(:secret_key!).and_return("secret-test")

      stub_request(:post, "#{api_base_url}/payments")
        .with(headers: {
          "Idempotence-Key" => payment.idempotency_key
        })
        .to_return(
          status: 200,
          body: {
            id: "2a9f1f13-000f-5000-9000-1d83d7f4462b",
            confirmation: {
              confirmation_url: "https://yookassa.test/confirmation"
            }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.new.create_top_up(
        payment: payment,
        return_url: return_url
      )

      expect(a_request(:post, "#{api_base_url}/payments").with { |request|
        body = JSON.parse(request.body)

        expect(request.headers).to include(
          "Content-Type" => "application/json",
          "Idempotence-Key" => payment.idempotency_key
        )
        expect(body).to include(
          "capture" => true,
          "description" => "Wallet top-up ##{payment.id}"
        )
        expect(body["amount"]).to eq(
          "value" => "123.45",
          "currency" => "GEL"
        )
        expect(body["confirmation"]).to eq(
          "type" => "redirect",
          "return_url" => return_url
        )
        expect(body["metadata"]).to include(
          "payment_id" => payment.id.to_s,
          "user_id" => payment.user_id.to_s,
          "operation_type" => "top_up",
          "source" => "wallet",
          "order_id" => "42"
        )
      }).to have_been_made.once

      expect(result.provider_payment_id).to eq("2a9f1f13-000f-5000-9000-1d83d7f4462b")
      expect(result.provider_checkout_session_id).to be_nil
      expect(result.confirmation_url).to eq("https://yookassa.test/confirmation")
      expect(result.raw_response).to include("id" => "2a9f1f13-000f-5000-9000-1d83d7f4462b")
    end
  end
end
