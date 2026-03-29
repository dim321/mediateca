module Billing
  class AccountOperation
    Result = Struct.new(:success?, :ledger_entry, :error, :idempotent?, keyword_init: true)

    private

    def with_account_lock(financial_account, &block)
      financial_account.with_lock(&block)
    end

    def find_existing_entry(financial_account, idempotency_key)
      return if idempotency_key.blank?

      financial_account.ledger_entries.find_by(idempotency_key: idempotency_key)
    end

    def success_result(ledger_entry, idempotent: false)
      Result.new(success?: true, ledger_entry: ledger_entry, error: nil, idempotent?: idempotent)
    end

    def failure_result(error)
      Result.new(success?: false, ledger_entry: nil, error: error, idempotent?: false)
    end

    def validate_positive_amount!(amount_cents)
      raise ServiceError, "Amount must be greater than 0" unless amount_cents.to_i.positive?
    end

    def build_metadata(metadata)
      metadata.presence || {}
    end

    class ServiceError < StandardError; end
  end
end
