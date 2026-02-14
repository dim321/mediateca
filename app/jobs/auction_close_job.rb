class AuctionCloseJob < ApplicationJob
  queue_as :auctions

  def perform(auction_id)
    auction = Auction.find(auction_id)
    return unless auction.open?

    Auctions::CloseAuctionService.new(auction: auction).call
  end
end
