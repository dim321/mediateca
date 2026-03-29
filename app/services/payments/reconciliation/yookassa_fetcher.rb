module Payments
  module Reconciliation
    class YookassaFetcher < BaseFetcher
      def initialize(connection: nil)
        @connection = connection
      end

      def fetch(payment)
        raise ArgumentError, "YooKassa payment #{payment.id} has no provider identifier" if payment.provider_payment_id.blank?

        response = connection.get("payments/#{payment.provider_payment_id}")
        body = normalize_response_body(response.body)

        Response.new(
          remote_status: map_status(body["status"]),
          payload: body,
          failure_reason: body.dig("cancellation_details", "reason") || body["status_description"]
        )
      end

      private

      attr_reader :connection

      def map_status(status)
        case status
        when "succeeded"
          :succeeded
        when "canceled"
          :canceled
        when "waiting_for_capture", "pending"
          :processing
        else
          :pending
        end
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
