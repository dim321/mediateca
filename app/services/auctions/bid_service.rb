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

      retries = 0
      begin
        ActiveRecord::Base.transaction do
          auction.reload
          validate_bid_amount! # Re-check after reload
          validate_user_balance!

          bid = Bid.create!(
            auction: auction,
            user: user,
            amount: amount
          )

          apply_bid_holds!(bid)

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
      result = Billing::AccountBalanceCheck.new(
        financial_account: financial_account,
        required_amount_cents: required_available_amount_cents
      ).call

      return if result.sufficient?

      raise ServiceError, "Недостаточно средств. Доступно: #{result.current_balance}, требуется: #{cents_to_amount(required_available_amount_cents)}"
    end

    def apply_bid_holds!(bid)
      hold_result = Billing::AccountHold.new(
        financial_account: financial_account,
        amount_cents: required_available_amount_cents,
        description: "Auction bid hold ##{auction.id}",
        reference: auction,
        idempotency_key: "auction:#{auction.id}:bid:#{bid.id}:hold",
        metadata: { bid_id: bid.id }
      ).call

      raise ServiceError, hold_result.error unless hold_result.success?

      return unless previous_highest_bidder && previous_highest_bidder != user && previous_highest_bid_cents.positive?

      release_result = Billing::AccountRelease.new(
        financial_account: previous_highest_bidder.financial_account!,
        amount_cents: previous_highest_bid_cents,
        description: "Auction outbid release ##{auction.id}",
        reference: auction,
        idempotency_key: "auction:#{auction.id}:bid:#{bid.id}:release:#{previous_highest_bidder.id}",
        metadata: { bid_id: bid.id, released_user_id: previous_highest_bidder.id }
      ).call

      raise ServiceError, release_result.error unless release_result.success?
    end

    def financial_account
      @financial_account ||= user.financial_account!
    end

    def required_available_amount_cents
      if previous_highest_bidder == user
        amount_cents - previous_highest_bid_cents
      else
        amount_cents
      end
    end

    def previous_highest_bidder
      @previous_highest_bidder ||= auction.highest_bidder
    end

    def previous_highest_bid_cents
      @previous_highest_bid_cents ||= decimal_to_cents(auction.current_highest_bid)
    end

    def amount_cents
      @amount_cents ||= decimal_to_cents(amount)
    end

    def decimal_to_cents(decimal_amount)
      return 0 if decimal_amount.blank?

      (decimal_amount.to_d * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
    end

    def cents_to_amount(cents)
      BigDecimal(cents, 0) / 100
    end

    class ServiceError < StandardError; end
  end
end
