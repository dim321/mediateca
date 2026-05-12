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
        auction.update!(auction_status: :closed)

        if auction.highest_bidder_id.present?
          winner = User.find(auction.highest_bidder_id)
          deduct_winner_balance(winner)
          if playlist
            create_scheduled_broadcast(winner)
          else
            update_time_slot_status
          end
        end
      end

      Result.new(success?: true, error: nil)
    rescue StandardError => e
      Result.new(success?: false, error: e.message)
    end

    private

    attr_reader :auction, :playlist

    def deduct_winner_balance(winner)
      result = Billing::DeductionService.new(
        user: winner,
        amount: auction.current_highest_bid,
        description: "Выигрыш аукциона ##{auction.id}",
        reference: auction
      ).call

      raise ServiceError, result.error unless result.success?
    end

    def create_scheduled_broadcast(winner)
      result = Broadcasts::ScheduleService.new(
        user: winner,
        playlist: playlist,
        time_slot: auction.time_slot,
        auction: auction
      ).call

      raise ServiceError, result.error unless result.success?
    end

    def update_time_slot_status
      auction.time_slot.update!(slot_status: :sold)
    end

    class ServiceError < StandardError; end
  end
end
