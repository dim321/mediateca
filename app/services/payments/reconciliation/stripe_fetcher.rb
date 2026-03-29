module Payments
  module Reconciliation
    class StripeFetcher < BaseFetcher
      def fetch(payment)
        payment_intent = retrieve_payment_intent(payment)

        Response.new(
          remote_status: map_status(payment_intent.status),
          payload: payment_intent.to_hash,
          failure_reason: payment_intent.try(:last_payment_error)&.try(:message)
        )
      end

      private

      def retrieve_payment_intent(payment)
        if payment.provider_payment_id.present?
          Stripe::PaymentIntent.retrieve(payment.provider_payment_id)
        elsif payment.provider_checkout_session_id.present?
          session = Stripe::Checkout::Session.retrieve(payment.provider_checkout_session_id)
          Stripe::PaymentIntent.retrieve(session.payment_intent)
        else
          raise ArgumentError, "Stripe payment #{payment.id} has no provider identifiers"
        end
      end

      def map_status(status)
        case status
        when "succeeded"
          :succeeded
        when "processing"
          :processing
        when "requires_action", "requires_confirmation", "requires_payment_method"
          :requires_action
        when "canceled"
          :canceled
        else
          :pending
        end
      end
    end
  end
end
