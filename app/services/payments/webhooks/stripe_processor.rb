module Payments
  module Webhooks
    class StripeProcessor < BaseProcessor
      def process(payment)
        case event_type
        when "checkout.session.completed"
          finalize_payment(payment)
        when "checkout.session.expired", "payment_intent.payment_failed"
          fail_payment(payment, status: :failed)
        else
          nil
        end
      end

      private

      def find_payment
        metadata = object["metadata"] || {}

        Payment.find_by(id: metadata["payment_id"]) ||
          Payment.find_by(provider: :stripe, provider_checkout_session_id: object["id"]) ||
          Payment.find_by(provider: :stripe, provider_payment_id: object["payment_intent"])
      end

      def update_provider_identifiers!(payment)
        payment.update!(
          provider_checkout_session_id: payment.provider_checkout_session_id.presence || object["id"],
          provider_payment_id: payment.provider_payment_id.presence || object["payment_intent"]
        )
      end

      def object
        payload.fetch("data").fetch("object")
      end
    end
  end
end
