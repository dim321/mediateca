module Billing
  class AccountHold < AccountOperation
    def initialize(financial_account:, amount_cents:, description:, currency: nil, payment: nil, reference: nil, idempotency_key: nil, metadata: {})
      @financial_account = financial_account
      @amount_cents = amount_cents.to_i
      @description = description
      @currency = currency || financial_account.currency
      @payment = payment
      @reference = reference
      @idempotency_key = idempotency_key
      @metadata = build_metadata(metadata)
    end

    def call
      validate_positive_amount!(amount_cents)

      with_account_lock(financial_account) do
        existing_entry = find_existing_entry(financial_account, idempotency_key)
        return success_result(existing_entry, idempotent: true) if existing_entry

        unless financial_account.available_amount_cents >= amount_cents
          raise ServiceError, "Insufficient available funds"
        end

        financial_account.available_amount_cents -= amount_cents
        financial_account.held_amount_cents += amount_cents
        financial_account.save!

        ledger_entry = financial_account.ledger_entries.create!(
          payment: payment,
          reference: reference,
          entry_type: :hold,
          amount_cents: -amount_cents,
          currency: currency,
          balance_after_cents: financial_account.available_amount_cents,
          held_after_cents: financial_account.held_amount_cents,
          description: description,
          idempotency_key: idempotency_key,
          metadata: metadata
        )

        success_result(ledger_entry)
      end
    rescue ServiceError => e
      failure_result(e.message)
    end

    private

    attr_reader :financial_account, :amount_cents, :description, :currency, :payment, :reference, :idempotency_key, :metadata
  end
end
