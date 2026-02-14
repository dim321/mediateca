class BidsController < ApplicationController
  skip_after_action :verify_policy_scoped, raise: false

  def create
    @auction = Auction.find(params[:auction_id])
    authorize @auction, :show?

    result = Auctions::BidService.new(
      user: current_user,
      auction: @auction,
      amount: params.dig(:bid, :amount)
    ).call

    if result.success?
      redirect_to auction_path(@auction), notice: "Ставка принята: #{result.bid.amount} руб."
    else
      redirect_to auction_path(@auction), alert: result.error
    end
  end
end
