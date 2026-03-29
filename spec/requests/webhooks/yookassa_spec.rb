require "rails_helper"

RSpec.describe "YooKassa webhooks", type: :request do
  let(:payload_hash) do
    {
      type: "notification",
      event: "payment.succeeded",
      object: {
        id: "2a9f1f13-000f-5000-9000-1d83d7f4462b",
        status: "succeeded"
      }
    }
  end
  let(:payload) { JSON.generate(payload_hash) }

  before do
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  describe "POST /webhooks/yookassa" do
    it "accepts an event, stores it once, and enqueues processing" do
      expect {
        post webhooks_yookassa_path, params: payload, headers: { "CONTENT_TYPE" => "application/json" }
      }.to change(PaymentWebhookEvent, :count).by(1)
        .and have_enqueued_job(ProcessPaymentWebhookJob).on_queue("payments")

      expect(response).to have_http_status(:ok)

      webhook_event = PaymentWebhookEvent.last
      expect(webhook_event).to be_yookassa
      expect(webhook_event.event_id).to eq("payment.succeeded:2a9f1f13-000f-5000-9000-1d83d7f4462b")
      expect(webhook_event.event_type).to eq("payment.succeeded")
    end

    it "stores duplicate events exactly once and does not enqueue a duplicate job" do
      expect {
        2.times { post webhooks_yookassa_path, params: payload, headers: { "CONTENT_TYPE" => "application/json" } }
      }.to change(PaymentWebhookEvent, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.count { |job| job[:job] == ProcessPaymentWebhookJob }).to eq(1)
    end

    it "returns bad request for invalid json" do
      post webhooks_yookassa_path, params: "{", headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:bad_request)
      expect(PaymentWebhookEvent.count).to eq(0)
    end
  end
end
