require "rails_helper"

RSpec.describe Payments::Reconciliation::YookassaFetcher do
  let(:api_base_url) { "https://api.yookassa.test/v3" }

  describe "#fetch" do
    it "maps canceled YooKassa payments to canceled" do
      payment = create(:payment, provider: :yookassa, provider_payment_id: "yo_cancel")

      allow(YookassaConfig).to receive(:api_base_url!).and_return(api_base_url)
      allow(YookassaConfig).to receive(:shop_id!).and_return("shop-test")
      allow(YookassaConfig).to receive(:secret_key!).and_return("secret-test")

      stub_request(:get, "#{api_base_url}/payments/yo_cancel")
        .to_return(
          status: 200,
          body: {
            id: "yo_cancel",
            status: "canceled",
            cancellation_details: { reason: "expired_on_confirmation" }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = described_class.new.fetch(payment)

      expect(result.remote_status).to eq(:canceled)
      expect(result.failure_reason).to eq("expired_on_confirmation")
      expect(result.payload).to include("id" => "yo_cancel", "status" => "canceled")
    end
  end
end
