module Webhooks
  class YookassaController < ActionController::API
    rescue_from JSON::ParserError, with: :bad_request

    def create
      payload = JSON.parse(request.raw_post)
      webhook_event, created = store_webhook_event(payload)
      ProcessPaymentWebhookJob.perform_later(webhook_event.id) if created

      head :ok
    end

    private

    def store_webhook_event(payload)
      event_type = payload.fetch("event")
      provider_payment_id = payload.fetch("object").fetch("id")
      event_id = "#{event_type}:#{provider_payment_id}"

      webhook_event = PaymentWebhookEvent.find_by(provider: :yookassa, event_id: event_id)
      return [ webhook_event, false ] if webhook_event

      created_event = PaymentWebhookEvent.create!(
        provider: :yookassa,
        event_id: event_id,
        event_type: event_type,
        payload: payload
      )

      [ created_event, true ]
    rescue ActiveRecord::RecordNotUnique
      [ PaymentWebhookEvent.find_by!(provider: :yookassa, event_id: event_id), false ]
    end

    def bad_request
      head :bad_request
    end
  end
end
