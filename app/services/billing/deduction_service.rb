module Billing
  class DeductionService
    Result = Struct.new(:success?, :transaction, :error, keyword_init: true)

    def initialize(user:, amount:, description:, reference: nil)
      @user = user
      @amount = amount.to_d
      @description = description
      @reference = reference
    end

    def call
      ActiveRecord::Base.transaction do
        # Pessimistic lock to prevent race conditions
        locked_user = User.lock("FOR UPDATE").find(user.id)

        unless locked_user.sufficient_balance?(amount)
          raise ServiceError, "Недостаточно средств. Баланс: #{locked_user.balance}, требуется: #{amount}"
        end

        txn = Transaction.create!(
          user: locked_user,
          amount: -amount,
          transaction_type: :deduction,
          description: description,
          reference: reference
        )

        locked_user.update!(balance: locked_user.balance - amount)

        Result.new(success?: true, transaction: txn, error: nil)
      end
    rescue ServiceError => e
      Result.new(success?: false, transaction: nil, error: e.message)
    end

    private

    attr_reader :user, :amount, :description, :reference

    class ServiceError < StandardError; end
  end
end
