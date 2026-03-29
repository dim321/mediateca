module Billing
  class AccountBalanceCheck
    Result = Struct.new(
      :sufficient?,
      :current_balance_cents,
      :current_balance,
      :deficit_cents,
      :deficit,
      keyword_init: true
    )

    def initialize(financial_account:, required_amount_cents:)
      @financial_account = financial_account
      @required_amount_cents = required_amount_cents.to_i
    end

    def call
      current_balance_cents = financial_account.available_amount_cents
      sufficient = current_balance_cents >= required_amount_cents
      deficit_cents = sufficient ? 0 : (required_amount_cents - current_balance_cents)

      Result.new(
        sufficient?: sufficient,
        current_balance_cents: current_balance_cents,
        current_balance: cents_to_amount(current_balance_cents),
        deficit_cents: deficit_cents,
        deficit: cents_to_amount(deficit_cents)
      )
    end

    private

    attr_reader :financial_account, :required_amount_cents

    def cents_to_amount(cents)
      BigDecimal(cents, 0) / 100
    end
  end
end
