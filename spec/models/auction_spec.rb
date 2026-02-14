require "rails_helper"

RSpec.describe Auction, type: :model do
  subject(:auction) { build(:auction) }

  describe "validations" do
    it { is_expected.to validate_numericality_of(:starting_price).is_greater_than(0) }

    it "validates uniqueness of time_slot_id" do
      create(:auction)
      expect(build(:auction, time_slot: Auction.last.time_slot)).not_to be_valid
    end

    it "validates closes_at is present" do
      auction.closes_at = nil
      expect(auction).not_to be_valid
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:auction_status).with_values(open: 0, closed: 1, cancelled: 2) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:time_slot) }
    it { is_expected.to have_many(:bids) }
  end

  describe "optimistic locking" do
    it "has lock_version column" do
      expect(Auction.column_names).to include("lock_version")
    end
  end

  describe "scopes" do
    let!(:open_auction) { create(:auction, :open) }
    let!(:closed_auction) { create(:auction, :closed) }

    it ".open returns only open auctions" do
      expect(Auction.open).to include(open_auction)
      expect(Auction.open).not_to include(closed_auction)
    end
  end
end
