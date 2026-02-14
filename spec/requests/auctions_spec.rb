require "rails_helper"

RSpec.describe "Auctions", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /auctions" do
    let!(:open_auction) { create(:auction, :open) }
    let!(:closed_auction) { create(:auction, :closed) }

    it "returns auctions list" do
      get auctions_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "filters by status" do
      get auctions_path(status: "open"), headers: html_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /auctions/:id" do
    let(:auction) { create(:auction) }

    it "returns auction details" do
      get auction_path(auction), headers: html_headers
      expect(response).to have_http_status(:ok)
    end
  end
end
