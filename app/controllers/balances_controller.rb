class BalancesController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped, raise: false

  def show
    @balance = current_user.balance
    @pagy, @transactions = pagy(
      :offset,
      current_user.transactions.order(created_at: :desc),
      limit: 20
    )
  end

  def deposit
    result = Billing::DepositService.new(
      user: current_user,
      amount: params.dig(:deposit, :amount)
    ).call

    if result.success?
      redirect_to balance_path,
                  notice: t("balances.flash.deposited", amount: helpers.number_to_currency(result.transaction.amount, unit: "₽", format: "%n %u"))
    else
      flash[:alert] = result.error
      redirect_to balance_path
    end
  end
end
