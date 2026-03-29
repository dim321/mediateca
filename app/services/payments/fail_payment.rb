module Payments
  class FailPayment
    Result = Struct.new(:success?, :payment, :error, :idempotent?, keyword_init: true)

    def initialize(payment:, payload:, status: :failed, failure_reason: nil)
      @payment = payment
      @payload = payload
      @status = status.to_sym
      @failure_reason = failure_reason
    end

    def call
      return success_result(payment, idempotent: true) if terminal_with_same_status?
      return failure_result("Succeeded payments cannot be failed") if payment.succeeded?

      payment.with_lock do
        return success_result(payment, idempotent: true) if terminal_with_same_status?
        return failure_result("Succeeded payments cannot be failed") if payment.succeeded?

        payment.update!(
          status: status,
          failed_at: Time.current,
          failure_reason: failure_reason || default_failure_reason,
          raw_response: payment.raw_response.deep_merge("webhook" => payload)
        )
      end

      success_result(payment.reload, idempotent: false)
    end

    private

    attr_reader :payment, :payload, :status, :failure_reason

    def terminal_with_same_status?
      payment.public_send("#{status}?")
    end

    def default_failure_reason
      payload["event_type"] || payload["event"] || "Payment failed"
    end

    def success_result(payment, idempotent:)
      Result.new(success?: true, payment: payment, error: nil, idempotent?: idempotent)
    end

    def failure_result(error)
      Result.new(success?: false, payment: payment, error: error, idempotent?: false)
    end
  end
end
