module Payments
  module Gateway
    class YookassaStrategy < Base
      def initialize(connection: nil)
        @connection = connection
      end

      def create_top_up(payment:, return_url:, **)
        response = connection.post("payments") do |request|
          request.headers["Content-Type"] = "application/json"
          request.headers["Idempotence-Key"] = payment.idempotency_key
          request.body = build_payload(payment: payment, return_url: return_url).to_json
        end

        body = normalize_response_body(response.body)

        Response.new(
          provider_payment_id: body["id"],
          confirmation_url: body.dig("confirmation", "confirmation_url"),
          raw_response: body
        )
      end

      private

      attr_reader :connection

      def build_payload(payment:, return_url:)
        {
          amount: {
            value: format_amount(payment.amount_cents),
            currency: payment.currency
          },
          capture: true,
          confirmation: {
            type: "redirect",
            return_url: return_url
          },
          description: top_up_description(payment),
          metadata: metadata_for(payment)
        }
      end

      def format_amount(amount_cents)
        format("%.2f", BigDecimal(amount_cents.to_s) / 100)
      end

      def normalize_response_body(body)
        return body if body.is_a?(Hash)

        JSON.parse(body)
      end

      def connection
        @connection ||= Faraday.new(url: YookassaConfig.api_base_url!) do |faraday|
          faraday.request :authorization, :basic, YookassaConfig.shop_id!, YookassaConfig.secret_key!
          faraday.request :json
          faraday.response :raise_error
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
