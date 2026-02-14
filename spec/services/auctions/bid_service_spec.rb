require "rails_helper"

RSpec.describe Auctions::BidService do
  let(:user) { create(:user, balance: 10_000) }
  let(:auction) { create(:auction, starting_price: 100, current_highest_bid: nil) }

  describe "#call" do
    context "with valid first bid" do
      it "creates a bid" do
        expect {
          described_class.new(user: user, auction: auction, amount: 150).call
        }.to change(Bid, :count).by(1)
      end

      it "updates auction current_highest_bid" do
        described_class.new(user: user, auction: auction, amount: 150).call
        expect(auction.reload.current_highest_bid.to_f).to eq(150.0)
      end

      it "updates auction highest_bidder" do
        described_class.new(user: user, auction: auction, amount: 150).call
        expect(auction.reload.highest_bidder_id).to eq(user.id)
      end

      it "returns successful result" do
        result = described_class.new(user: user, auction: auction, amount: 150).call
        expect(result).to be_success
      end
    end

    context "when bid is too low" do
      before { auction.update!(current_highest_bid: 200, highest_bidder_id: create(:user).id) }

      it "returns failure" do
        result = described_class.new(user: user, auction: auction, amount: 150).call
        expect(result).not_to be_success
        expect(result.error).to include("выше")
      end
    end

    context "when auction is closed" do
      let(:auction) { create(:auction, :closed) }

      it "returns failure" do
        result = described_class.new(user: user, auction: auction, amount: 500).call
        expect(result).not_to be_success
        expect(result.error).to include("закрыт")
      end
    end

    context "when insufficient balance" do
      let(:poor_user) { create(:user, balance: 50) }

      it "returns failure" do
        result = described_class.new(user: poor_user, auction: auction, amount: 500).call
        expect(result).not_to be_success
        expect(result.error).to include("Недостаточно")
      end
    end
  end
end
