module Payments
  class CreateTopUp
    Result = Struct.new(:success?, :payment, :redirect_url, :error, keyword_init: true)

    def initialize(user:, provider:, amount:, success_url:, cancel_url:)
      @user = user
      @provider = provider.to_s
      @amount = amount
      @success_url = success_url
      @cancel_url = cancel_url
    end

    def call
      return failure_result("Unsupported payment provider") unless Payment.providers.key?(provider)

      amount_cents = parse_amount_cents(amount)
      payment = build_payment(amount_cents)
      gateway_response = create_gateway_payment(payment)

      payment.update!(
        provider_payment_id: gateway_response.provider_payment_id,
        provider_checkout_session_id: gateway_response.provider_checkout_session_id,
        confirmation_url: gateway_response.confirmation_url,
        return_url: success_url,
        raw_response: gateway_response.raw_response
      )

      success_result(payment)
    rescue AmountError => e
      failure_result(e.message)
    rescue StandardError => e
      payment&.update(status: :failed, failure_reason: e.message) if payment&.persisted? && payment.pending?
      failure_result(e.message)
    end

    private

    attr_reader :user, :provider, :amount, :success_url, :cancel_url

    def build_payment(amount_cents)
      financial_account = user.financial_account!

      Payment.create!(
        user: user,
        financial_account: financial_account,
        provider: provider,
        operation_type: :top_up,
        status: :pending,
        amount_cents: amount_cents,
        currency: financial_account.currency,
        idempotency_key: SecureRandom.uuid,
        metadata: {
          "cancel_url" => cancel_url
        }
      )
    end

    def create_gateway_payment(payment)
      gateway = GatewayResolver.call(provider: payment.provider)

      gateway.create_top_up(
        payment: payment,
        success_url: success_url,
        cancel_url: cancel_url,
        return_url: success_url
      )
    end

    def parse_amount_cents(raw_amount)
      amount_decimal = BigDecimal(raw_amount.to_s)
      raise AmountError, "Amount must be greater than 0" unless amount_decimal.positive?

      (amount_decimal * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
    rescue ArgumentError
      raise AmountError, "Amount is invalid"
    end

    def success_result(payment)
      Result.new(success?: true, payment: payment, redirect_url: payment.confirmation_url, error: nil)
    end

    def failure_result(error)
      Result.new(success?: false, payment: nil, redirect_url: nil, error: error)
    end

    class AmountError < StandardError; end
  end
end
