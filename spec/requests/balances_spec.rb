require "rails_helper"

RSpec.describe "Balances", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user, balance: 5000) }

  before { sign_in user }

  describe "GET /balance" do
    let!(:transaction1) { create(:transaction, :deposit, user: user) }
    let!(:transaction2) { create(:transaction, :deduction, user: user) }

    it "returns balance page" do
      get balance_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /balance/deposit" do
    it "deposits with valid amount" do
      expect {
        post deposit_balance_path, params: { deposit: { amount: "1000" } }, headers: html_headers
      }.to change(Transaction, :count).by(1)

      expect(user.reload.balance.to_f).to eq(6000.0)
    end

    it "rejects invalid amount" do
      expect {
        post deposit_balance_path, params: { deposit: { amount: "0" } }, headers: html_headers
      }.not_to change(Transaction, :count)
    end

    it "redirects on success" do
      post deposit_balance_path, params: { deposit: { amount: "1000" } }, headers: html_headers
      expect(response).to redirect_to(balance_path)
    end
  end
end
