require "rails_helper"

RSpec.describe Auctions::CloseAuctionService do
  let(:winner) { create(:user, balance: 10_000) }
  let(:device) { create(:broadcast_device) }
  let(:time_slot) { create(:time_slot, :available, broadcast_device: device) }
  let(:auction) { create(:auction, :open, time_slot: time_slot, starting_price: 100, current_highest_bid: 500, highest_bidder_id: winner.id) }
  let(:playlist) { create(:playlist, user: winner, total_duration: 1500) }

  before do
    create(:bid, auction: auction, user: winner, amount: 500)
  end

  describe "#call" do
    context "with winning bid" do
      it "closes the auction" do
        described_class.new(auction: auction, playlist: playlist).call
        expect(auction.reload).to be_closed
      end

      it "deducts winner balance" do
        described_class.new(auction: auction, playlist: playlist).call
        expect(winner.reload.balance.to_f).to eq(9500.0)
      end

      it "creates a scheduled broadcast" do
        expect {
          described_class.new(auction: auction, playlist: playlist).call
        }.to change(ScheduledBroadcast, :count).by(1)
      end

      it "updates time slot status to sold" do
        described_class.new(auction: auction, playlist: playlist).call
        expect(time_slot.reload).to be_sold
      end
    end

    context "without bids" do
      let(:empty_auction) { create(:auction, :open, starting_price: 100, current_highest_bid: nil, highest_bidder_id: nil) }

      it "closes the auction without creating broadcast" do
        described_class.new(auction: empty_auction).call
        expect(empty_auction.reload).to be_closed
        expect(ScheduledBroadcast.count).to eq(0)
      end
    end

    context "when already closed" do
      let(:closed_auction) { create(:auction, :closed) }

      it "skips processing" do
        result = described_class.new(auction: closed_auction).call
        expect(result).to be_success
      end
    end
  end
end
