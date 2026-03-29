module Payments
  class ProcessWebhookEvent
    Result = Struct.new(:success?, :payment_webhook_event, :payment, :error, :ignored?, keyword_init: true)

    def initialize(payment_webhook_event:)
      @payment_webhook_event = payment_webhook_event
    end

    def call
      return success_result(nil, ignored: true) if payment_webhook_event.processed_at.present?

      payment = process_event
      payment_webhook_event.update!(processed_at: Time.current)

      success_result(payment)
    rescue StandardError => e
      Result.new(success?: false, payment_webhook_event: payment_webhook_event, payment: nil, error: e.message, ignored?: false)
    end

    private

    attr_reader :payment_webhook_event

    def process_event
      processor&.call
    end

    def success_result(payment, ignored: false)
      Result.new(success?: true, payment_webhook_event: payment_webhook_event, payment: payment, error: nil, ignored?: ignored)
    end

    def processor
      case payment_webhook_event.provider
      when "stripe"
        Payments::Webhooks::StripeProcessor.new(payment_webhook_event: payment_webhook_event)
      when "yookassa"
        Payments::Webhooks::YookassaProcessor.new(payment_webhook_event: payment_webhook_event)
      end
    end
  end
end
