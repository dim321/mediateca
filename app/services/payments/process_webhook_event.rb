module Payments
  class ProcessWebhookEvent
    Result = Struct.new(:success?, :payment_webhook_event, keyword_init: true)

    def initialize(payment_webhook_event:)
      @payment_webhook_event = payment_webhook_event
    end

    def call
      Result.new(success?: true, payment_webhook_event: payment_webhook_event)
    end

    private

    attr_reader :payment_webhook_event
  end
end
