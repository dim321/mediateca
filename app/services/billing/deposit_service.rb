module Billing
  class DepositService
    Result = Struct.new(:success?, :transaction, :error, keyword_init: true)

    def initialize(user:, amount:)
      @user = user
      @amount = amount.to_d
    end

    def call
      validate_amount!

      ActiveRecord::Base.transaction do
        txn = Transaction.create!(
          user: user,
          amount: amount,
          transaction_type: :deposit,
          description: "Пополнение баланса"
        )

        user.update!(balance: user.balance + amount)

        Result.new(success?: true, transaction: txn, error: nil)
      end
    rescue ServiceError => e
      Result.new(success?: false, transaction: nil, error: e.message)
    end

    private

    attr_reader :user, :amount

    def validate_amount!
      raise ServiceError, "Сумма должна быть больше 0" unless amount > 0
    end

    class ServiceError < StandardError; end
  end
end
