require "rails_helper"

RSpec.describe Payments::Reconciliation::StripeFetcher do
  describe "#fetch" do
    it "maps succeeded payment intents to succeeded" do
      payment = create(:payment, provider: :stripe, provider_payment_id: "pi_success")
      payment_intent = double(status: "succeeded", to_hash: { "id" => "pi_success" }, last_payment_error: nil)

      allow(Stripe::PaymentIntent).to receive(:retrieve).with("pi_success").and_return(payment_intent)

      result = described_class.new.fetch(payment)

      expect(result.remote_status).to eq(:succeeded)
      expect(result.payload).to eq({ "id" => "pi_success" })
      expect(result.failure_reason).to be_nil
    end
  end
end
