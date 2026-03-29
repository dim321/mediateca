module Payments
  module Webhooks
    class YookassaProcessor < BaseProcessor
      def process(payment)
        case event_type
        when "payment.succeeded"
          finalize_payment(payment)
        when "payment.canceled"
          fail_payment(payment, status: :canceled)
        else
          nil
        end
      end

      private

      def find_payment
        metadata = object["metadata"] || {}

        Payment.find_by(id: metadata["payment_id"]) ||
          Payment.find_by(provider: :yookassa, provider_payment_id: object["id"])
      end

      def update_provider_identifiers!(payment)
        payment.update!(
          provider_payment_id: payment.provider_payment_id.presence || object["id"]
        )
      end

      def object
        payload.fetch("object")
      end
    end
  end
end
