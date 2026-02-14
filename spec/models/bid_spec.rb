require "rails_helper"

RSpec.describe Bid, type: :model do
  subject(:bid) { build(:bid) }

  describe "validations" do
    it { is_expected.to validate_numericality_of(:amount).is_greater_than(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:auction) }
    it { is_expected.to belong_to(:user) }
  end

  describe "ordering" do
    let(:auction) { create(:auction) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "orders by created_at for tie-breaking (FR-025)" do
      bid1 = create(:bid, auction: auction, user: user1, amount: 200, created_at: 2.minutes.ago)
      bid2 = create(:bid, auction: auction, user: user2, amount: 200, created_at: 1.minute.ago)
      expect(auction.bids.order(:created_at)).to eq([bid1, bid2])
    end
  end
end
