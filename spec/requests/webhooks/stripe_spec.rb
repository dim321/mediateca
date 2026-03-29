require "rails_helper"

RSpec.describe "Stripe webhooks", type: :request do
  let(:payload_hash) do
    {
      id: "evt_test_webhook_123",
      object: "event",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_123",
          object: "checkout.session"
        }
      }
    }
  end
  let(:payload) { JSON.generate(payload_hash) }
  let(:webhook_secret) { "whsec_test_123" }
  let(:timestamp) { Time.now }
  let(:signature_header) do
    Stripe::Webhook::Signature.generate_header(
      timestamp,
      Stripe::Webhook::Signature.compute_signature(timestamp, payload, webhook_secret)
    )
  end

  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    allow(StripeConfig).to receive(:webhook_secret!).and_return(webhook_secret)
  end

  describe "POST /webhooks/stripe" do
    it "accepts a valid signed event, stores it once, and enqueues processing" do
      expect {
        post webhooks_stripe_path, params: payload, headers: {
          "CONTENT_TYPE" => "application/json",
          "Stripe-Signature" => signature_header
        }
      }.to change(PaymentWebhookEvent, :count).by(1)
        .and have_enqueued_job(ProcessPaymentWebhookJob).on_queue("payments")

      expect(response).to have_http_status(:ok)

      webhook_event = PaymentWebhookEvent.last
      expect(webhook_event).to be_stripe
      expect(webhook_event.event_id).to eq("evt_test_webhook_123")
      expect(webhook_event.event_type).to eq("checkout.session.completed")
      expect(webhook_event.payload).to include("id" => "evt_test_webhook_123", "type" => "checkout.session.completed")
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.last[:args]).to eq([ webhook_event.id ])
    end

    it "returns bad request for an invalid signature" do
      post webhooks_stripe_path, params: payload, headers: {
        "CONTENT_TYPE" => "application/json",
        "Stripe-Signature" => "t=1,v1=invalid"
      }

      expect(response).to have_http_status(:bad_request)
      expect(PaymentWebhookEvent.count).to eq(0)
    end

    it "stores duplicate events exactly once and does not enqueue a duplicate job" do
      headers = {
        "CONTENT_TYPE" => "application/json",
        "Stripe-Signature" => signature_header
      }

      expect {
        2.times { post webhooks_stripe_path, params: payload, headers: headers }
      }.to change(PaymentWebhookEvent, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count { |job| job[:job] == ProcessPaymentWebhookJob }).to eq(1)
    end
  end
end
