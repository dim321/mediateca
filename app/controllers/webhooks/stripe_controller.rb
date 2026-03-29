module Webhooks
  class StripeController < ActionController::API
    rescue_from JSON::ParserError, with: :bad_request
    rescue_from Stripe::SignatureVerificationError, with: :bad_request

    def create
      event = Stripe::Webhook.construct_event(
        request.raw_post,
        request.headers["Stripe-Signature"],
        StripeConfig.webhook_secret!
      )

      webhook_event, created = store_webhook_event(event)
      ProcessPaymentWebhookJob.perform_later(webhook_event.id) if created

      head :ok
    end

    private

    def store_webhook_event(event)
      webhook_event = PaymentWebhookEvent.find_by(provider: :stripe, event_id: event.id)
      return [ webhook_event, false ] if webhook_event

      created_event = PaymentWebhookEvent.create!(
        provider: :stripe,
        event_id: event.id,
        event_type: event.type,
        payload: event.to_hash
      )

      [ created_event, true ]
    rescue ActiveRecord::RecordNotUnique
      [ PaymentWebhookEvent.find_by!(provider: :stripe, event_id: event.id), false ]
    end

    def bad_request
      head :bad_request
    end
  end
end
