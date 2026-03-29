module Payments
  module Gateway
    class StripeStrategy < Base
      def create_top_up(payment:, success_url:, cancel_url:)
        session = Stripe::Checkout::Session.create(
          build_payload(payment: payment, success_url: success_url, cancel_url: cancel_url),
          { idempotency_key: payment.idempotency_key }
        )

        Response.new(
          provider_payment_id: session.payment_intent,
          provider_checkout_session_id: session.id,
          confirmation_url: session.url,
          raw_response: session.to_hash
        )
      end

      private

      def build_payload(payment:, success_url:, cancel_url:)
        metadata = metadata_for(payment)

        {
          mode: "payment",
          success_url: success_url,
          cancel_url: cancel_url,
          client_reference_id: payment.user_id.to_s,
          metadata: metadata,
          line_items: [
            {
              quantity: 1,
              price_data: {
                currency: payment.currency.downcase,
                unit_amount: payment.amount_cents,
                product_data: {
                  name: top_up_description(payment),
                  metadata: metadata
                }
              }
            }
          ],
          payment_intent_data: {
            metadata: metadata
          }
        }
      end
    end
  end
end
