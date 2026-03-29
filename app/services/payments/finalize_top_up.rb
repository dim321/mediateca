module Payments
  class FinalizeTopUp
    Result = Struct.new(:success?, :payment, :ledger_entry, :error, :idempotent?, keyword_init: true)

    def initialize(payment:, payload:)
      @payment = payment
      @payload = payload
    end

    def call
      return success_result(payment, nil, idempotent: true) if payment.succeeded?
      return failure_result("Payment is not a top-up") unless payment.top_up?

      payment.with_lock do
        return success_result(payment, payment.ledger_entries.order(:id).last, idempotent: true) if payment.succeeded?

        credit_result = Billing::AccountCredit.new(
          financial_account: payment.financial_account,
          amount_cents: payment.amount_cents,
          description: "Top-up settled ##{payment.id}",
          currency: payment.currency,
          payment: payment,
          reference: payment,
          idempotency_key: "payment:#{payment.id}:settled",
          metadata: { provider: payment.provider, webhook_payload: payload }
        ).call

        return failure_result(credit_result.error) unless credit_result.success?

        payment.update!(
          status: :succeeded,
          paid_at: Time.current,
          failure_reason: nil,
          raw_response: merge_raw_response(payload)
        )

        success_result(payment, credit_result.ledger_entry, idempotent: credit_result.idempotent?)
      end
    end

    private

    attr_reader :payment, :payload

    def merge_raw_response(webhook_payload)
      payment.raw_response.deep_merge("webhook" => webhook_payload)
    end

    def success_result(payment, ledger_entry, idempotent:)
      Result.new(success?: true, payment: payment, ledger_entry: ledger_entry, error: nil, idempotent?: idempotent)
    end

    def failure_result(error)
      Result.new(success?: false, payment: payment, ledger_entry: nil, error: error, idempotent?: false)
    end
  end
end
