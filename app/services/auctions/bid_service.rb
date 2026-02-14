module Auctions
  class BidService
    Result = Struct.new(:success?, :bid, :error, keyword_init: true)

    MAX_RETRIES = 3

    def initialize(user:, auction:, amount:)
      @user = user
      @auction = auction
      @amount = amount.to_d
    end

    def call
      validate_auction_open!
      validate_bid_amount!
      validate_user_balance!

      retries = 0
      begin
        ActiveRecord::Base.transaction do
          auction.reload
          validate_bid_amount! # Re-check after reload

          bid = Bid.create!(
            auction: auction,
            user: user,
            amount: amount
          )

          auction.update!(
            current_highest_bid: amount,
            highest_bidder_id: user.id
          )

          Result.new(success?: true, bid: bid, error: nil)
        end
      rescue ActiveRecord::StaleObjectError
        retries += 1
        retry if retries < MAX_RETRIES
        Result.new(success?: false, bid: nil, error: "Аукцион был обновлён другим пользователем. Обновите страницу и попробуйте снова.")
      end
    rescue ServiceError => e
      Result.new(success?: false, bid: nil, error: e.message)
    end

    private

    attr_reader :user, :auction, :amount

    def validate_auction_open!
      raise ServiceError, "Аукцион закрыт" unless auction.open?
    end

    def validate_bid_amount!
      min_amount = auction.current_highest_bid || auction.starting_price
      if amount <= min_amount
        raise ServiceError, "Ставка должна быть выше текущей (#{min_amount})"
      end
    end

    def validate_user_balance!
      unless user.sufficient_balance?(amount)
        raise ServiceError, "Недостаточно средств. Баланс: #{user.balance}, ставка: #{amount}"
      end
    end

    class ServiceError < StandardError; end
  end
end
