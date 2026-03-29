require "rails_helper"

RSpec.describe "Balances", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user, balance: 5000) }
  let!(:financial_account) { create(:financial_account, user: user, currency: "USD", available_amount_cents: 500_000, held_amount_cents: 15_000) }

  before { sign_in user }

  describe "GET /balance" do
    let!(:ledger_entry1) do
      create(
        :ledger_entry,
        financial_account: financial_account,
        entry_type: :deposit_settled,
        amount_cents: 5_000,
        currency: "USD",
        balance_after_cents: 505_000,
        held_after_cents: 15_000,
        description: "Balance top-up settled"
      )
    end

    let!(:ledger_entry2) do
      create(
        :ledger_entry,
        financial_account: financial_account,
        entry_type: :hold,
        amount_cents: -2_000,
        currency: "USD",
        balance_after_cents: 503_000,
        held_after_cents: 17_000,
        description: "Auction hold"
      )
    end

    it "returns balance page" do
      get balance_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "renders balance from financial_account" do
      get balance_path, headers: html_headers

      expect(response.body).to include("$5 000,00")
    end

    it "renders held balance from financial_account" do
      get balance_path, headers: html_headers

      expect(response.body).to include("$150,00")
    end

    it "renders ledger entry history" do
      get balance_path, headers: html_headers

      expect(response.body).to include("Balance top-up settled")
      expect(response.body).to include("Auction hold")
    end

    it "formats amounts using the account currency" do
      get balance_path, headers: html_headers

      expect(response.body).to include("$")
      expect(response.body).not_to include("₽")
    end
  end
end
