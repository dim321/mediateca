class TopUpsController < ApplicationController
  skip_after_action :verify_authorized, only: [ :success, :cancel ]
  skip_after_action :verify_policy_scoped, raise: false

  def create
    authorize Payment

    result = Payments::CreateTopUp.new(
      user: current_user,
      provider: top_up_params[:provider],
      amount: top_up_params[:amount],
      success_url: success_top_ups_url,
      cancel_url: cancel_top_ups_url
    ).call

    if result.success?
      redirect_to result.redirect_url, allow_other_host: true
    else
      redirect_to balance_path, alert: result.error
    end
  end

  def success
    redirect_to balance_path, notice: t("top_ups.flash.awaiting_confirmation")
  end

  def cancel
    redirect_to balance_path, alert: t("top_ups.flash.canceled")
  end

  private

  def top_up_params
    params.expect(top_up: [ :provider, :amount ])
  end
end
