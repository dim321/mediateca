require "rails_helper"

RSpec.describe ProcessPaymentWebhookJob, type: :job do
  let(:payment_webhook_event) { create(:payment_webhook_event) }

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  describe "#perform" do
    it "is enqueued in payments queue" do
      expect {
        described_class.perform_later(payment_webhook_event.id)
      }.to have_enqueued_job(described_class).on_queue("payments")
    end

    it "calls Payments::ProcessWebhookEvent" do
      processor = instance_double(Payments::ProcessWebhookEvent, call: Struct.new(:success?).new(true))
      allow(Payments::ProcessWebhookEvent).to receive(:new).and_return(processor)

      described_class.perform_now(payment_webhook_event.id)

      expect(Payments::ProcessWebhookEvent).to have_received(:new).with(payment_webhook_event: payment_webhook_event)
    end

    it "handles missing events gracefully" do
      expect { described_class.perform_now(-1) }.not_to raise_error
    end
  end
end
