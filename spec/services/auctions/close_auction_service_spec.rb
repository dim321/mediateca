require "rails_helper"

RSpec.describe Auctions::CloseAuctionService do
  let(:winner) { create(:user, balance: 10_000) }
  let!(:winner_account) { create(:financial_account, user: winner, currency: "USD", available_amount_cents: 950_000, held_amount_cents: 50_000) }
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

      it "captures held winner funds" do
        described_class.new(auction: auction, playlist: playlist).call
        winner_account.reload
        expect(winner_account.available_amount_cents).to eq(950_000)
        expect(winner_account.held_amount_cents).to eq(0)
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

      it "creates a capture ledger entry" do
        result = described_class.new(auction: auction, playlist: playlist).call

        expect(result).to be_success
        expect(winner_account.ledger_entries.order(:id).last).to be_capture
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

    context "when capture fails" do
      before do
        winner_account.update!(held_amount_cents: 0)
      end

      it "returns failure" do
        result = described_class.new(auction: auction, playlist: playlist).call

        expect(result).not_to be_success
        expect(result.error).to include("Insufficient held funds")
      end

      it "does not create a scheduled broadcast" do
        expect {
          described_class.new(auction: auction, playlist: playlist).call
        }.not_to change(ScheduledBroadcast, :count)
      end

      it "does not mark the time slot as sold" do
        described_class.new(auction: auction, playlist: playlist).call

        expect(time_slot.reload).to be_available
      end

      it "does not close the auction" do
        described_class.new(auction: auction, playlist: playlist).call

        expect(auction.reload).to be_open
      end
    end
  end
end
