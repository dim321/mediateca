module Billing
  class BalanceCheckService
    Result = Struct.new(:sufficient?, :current_balance, :deficit, keyword_init: true)

    def initialize(user:, required_amount:)
      @user = user
      @required_amount = required_amount.to_d
    end

    def call
      current = user.balance
      sufficient = current >= required_amount
      deficit = sufficient ? 0 : (required_amount - current)

      Result.new(sufficient?: sufficient, current_balance: current, deficit: deficit)
    end

    private

    attr_reader :user, :required_amount
  end
end
