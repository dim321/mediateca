require "rails_helper"

RSpec.describe Auctions::BidService do
  let(:user) { create(:user, balance: 10_000) }
  let!(:financial_account) { create(:financial_account, user: user, currency: "USD", available_amount_cents: 1_000_000, held_amount_cents: 0) }
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

      it "places a hold on the bidder financial account" do
        described_class.new(user: user, auction: auction, amount: 150).call

        financial_account.reload
        expect(financial_account.available_amount_cents).to eq(985_000)
        expect(financial_account.held_amount_cents).to eq(15_000)
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
      let!(:poor_account) { create(:financial_account, user: poor_user, currency: "USD", available_amount_cents: 5_000, held_amount_cents: 0) }

      it "returns failure" do
        result = described_class.new(user: poor_user, auction: auction, amount: 500).call
        expect(result).not_to be_success
        expect(result.error).to include("Недостаточно")
      end
    end

    context "when the highest bidder raises their own bid" do
      before do
        auction.update!(current_highest_bid: 150, highest_bidder_id: user.id)
        Billing::AccountHold.new(
          financial_account: financial_account,
          amount_cents: 15_000,
          description: "Initial auction hold",
          reference: auction,
          idempotency_key: "initial-hold"
        ).call
      end

      it "holds only the bid delta" do
        described_class.new(user: user, auction: auction, amount: 200).call

        financial_account.reload
        expect(financial_account.available_amount_cents).to eq(980_000)
        expect(financial_account.held_amount_cents).to eq(20_000)
      end
    end

    context "when a bidder is outbid" do
      let(:previous_bidder) { create(:user, balance: 10_000) }
      let!(:previous_account) { create(:financial_account, user: previous_bidder, currency: "USD", available_amount_cents: 985_000, held_amount_cents: 15_000) }

      before do
        auction.update!(current_highest_bid: 150, highest_bidder_id: previous_bidder.id)
      end

      it "releases the previous highest bidder hold" do
        described_class.new(user: user, auction: auction, amount: 200).call

        previous_account.reload
        expect(previous_account.available_amount_cents).to eq(1_000_000)
        expect(previous_account.held_amount_cents).to eq(0)
      end

      it "creates hold and release ledger entries" do
        expect {
          described_class.new(user: user, auction: auction, amount: 200).call
        }.to change(LedgerEntry, :count).by(2)
      end
    end
  end
end
