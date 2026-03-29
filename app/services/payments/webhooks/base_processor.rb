module Payments
  module Webhooks
    class BaseProcessor
      def initialize(payment_webhook_event:)
        @payment_webhook_event = payment_webhook_event
      end

      def call
        payment = find_payment
        return nil unless payment

        process(payment)
      end

      private

      attr_reader :payment_webhook_event

      def payload
        payment_webhook_event.payload
      end

      def event_type
        payment_webhook_event.event_type
      end

      def finalize_payment(payment)
        update_provider_identifiers!(payment)
        result = Payments::FinalizeTopUp.new(payment: payment, payload: payload).call
        raise StandardError, result.error unless result.success?

        result.payment
      end

      def fail_payment(payment, status:)
        update_provider_identifiers!(payment)
        result = Payments::FailPayment.new(payment: payment, payload: payload, status: status).call
        raise StandardError, result.error unless result.success?

        result.payment
      end

      def find_payment
        raise NotImplementedError
      end

      def process(_payment)
        raise NotImplementedError
      end

      def update_provider_identifiers!(_payment)
        raise NotImplementedError
      end
    end
  end
end
