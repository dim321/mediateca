module Payments
  module Gateway
    class Base
      Response = Struct.new(
        :provider_payment_id,
        :provider_checkout_session_id,
        :confirmation_url,
        :raw_response,
        keyword_init: true
      )

      def create_top_up(**)
        raise NotImplementedError, "#{self.class.name} must implement #create_top_up"
      end

      private

      def metadata_for(payment)
        {
          "payment_id" => payment.id.to_s,
          "user_id" => payment.user_id.to_s,
          "operation_type" => payment.operation_type
        }.merge(stringify_metadata(payment.metadata))
      end

      def stringify_metadata(metadata)
        metadata.to_h.deep_stringify_keys.transform_values do |value|
          value.is_a?(String) ? value : value.to_json
        end
      end

      def top_up_description(payment)
        "Wallet top-up ##{payment.id}"
      end
    end
  end
end
