class AuctionsController < ApplicationController
  def index
    scope = policy_scope(Auction)
      .includes(time_slot: :broadcast_device)
      .order(closes_at: :asc)

    scope = scope.where(auction_status: params[:status]) if params[:status].present?

    @pagy, @auctions = pagy(:offset, scope, limit: 20)
  end

  def show
    @auction = Auction.includes(:bids, time_slot: :broadcast_device).find(params[:id])
    authorize @auction
    @bids = @auction.bids.order(amount: :desc, created_at: :asc)
    @my_bids = @auction.bids.where(user: current_user).order(created_at: :desc)
  end
end
