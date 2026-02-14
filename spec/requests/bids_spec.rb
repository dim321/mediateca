require "rails_helper"

RSpec.describe "Bids", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user, balance: 10_000) }
  let(:auction) { create(:auction, :open, starting_price: 100) }

  before { sign_in user }

  describe "POST /auctions/:auction_id/bids" do
    it "creates a bid with valid amount" do
      expect {
        post auction_bids_path(auction), params: { bid: { amount: 200 } }, headers: html_headers
      }.to change(Bid, :count).by(1)
    end

    it "redirects to auction on success" do
      post auction_bids_path(auction), params: { bid: { amount: 200 } }, headers: html_headers
      expect(response).to redirect_to(auction_path(auction))
    end

    it "rejects bid lower than starting price" do
      expect {
        post auction_bids_path(auction), params: { bid: { amount: 50 } }, headers: html_headers
      }.not_to change(Bid, :count)
    end

    context "with insufficient balance" do
      let(:poor_user) { create(:user, balance: 50) }

      before { sign_in poor_user }

      it "rejects bid" do
        expect {
          post auction_bids_path(auction), params: { bid: { amount: 200 } }, headers: html_headers
        }.not_to change(Bid, :count)
      end
    end
  end
end
