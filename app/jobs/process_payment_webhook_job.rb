class ProcessPaymentWebhookJob < ApplicationJob
  queue_as :payments

  def perform(payment_webhook_event_id)
    payment_webhook_event = PaymentWebhookEvent.find_by(id: payment_webhook_event_id)
    return unless payment_webhook_event

    Payments::ProcessWebhookEvent.new(payment_webhook_event: payment_webhook_event).call
  end
end
