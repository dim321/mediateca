module Auctions
  class CloseAuctionService
    Result = Struct.new(:success?, :error, keyword_init: true)

    def initialize(auction:, playlist: nil)
      @auction = auction
      @playlist = playlist
    end

    def call
      return Result.new(success?: true, error: nil) unless auction.open?

      ActiveRecord::Base.transaction do
        if auction.highest_bidder_id.present?
          winner = User.find(auction.highest_bidder_id)
          capture_winner_hold!(winner)
          create_scheduled_broadcast(winner) if playlist
          update_time_slot_status
        end

        auction.update!(auction_status: :closed)
      end

      Result.new(success?: true, error: nil)
    rescue ServiceError, StandardError => e
      Result.new(success?: false, error: e.message)
    end

    private

    attr_reader :auction, :playlist

    def capture_winner_hold!(winner)
      result = Billing::AccountCapture.new(
        financial_account: winner.financial_account!,
        amount_cents: winning_amount_cents,
        description: "Auction win capture ##{auction.id}",
        reference: auction
      ).call

      raise ServiceError, result.error unless result.success?
    end

    def create_scheduled_broadcast(winner)
      Broadcasts::ScheduleService.new(
        user: winner,
        playlist: playlist,
        time_slot: auction.time_slot,
        auction: auction
      ).call
    end

    def update_time_slot_status
      auction.time_slot.update!(slot_status: :sold)
    end

    def winning_amount_cents
      (auction.current_highest_bid.to_d * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
    end

    class ServiceError < StandardError; end
  end
end
