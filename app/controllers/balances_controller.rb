class BalancesController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped, raise: false

  def show
    @financial_account = current_user.financial_account!
    @balance = @financial_account.available_amount
    @held_balance = @financial_account.held_amount
    @pagy, @ledger_entries = pagy(
      :offset,
      @financial_account.ledger_entries.order(created_at: :desc),
      limit: 20
    )
  end
end
