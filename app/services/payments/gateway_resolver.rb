module Payments
  class GatewayResolver
    def self.call(provider:)
      new(provider: provider).call
    end

    def initialize(provider:)
      @provider = provider.to_s
    end

    def call
      case provider
      when "stripe"
        Gateway::StripeStrategy.new
      when "yookassa"
        Gateway::YookassaStrategy.new
      else
        raise ArgumentError, "Unsupported payment provider: #{provider}"
      end
    end

    private

    attr_reader :provider
  end
end
