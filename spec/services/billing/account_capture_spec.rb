require "rails_helper"

RSpec.describe Billing::AccountCapture do
  let(:financial_account) { create(:financial_account, available_amount_cents: 3_500, held_amount_cents: 1_500) }

  describe "#call" do
    it "reduces held balance" do
      described_class.new(
        financial_account: financial_account,
        amount_cents: 1_000,
        description: "Capture auction hold"
      ).call

      financial_account.reload
      expect(financial_account.available_amount_cents).to eq(3_500)
      expect(financial_account.held_amount_cents).to eq(500)
    end

    it "creates a capture ledger entry" do
      result = described_class.new(
        financial_account: financial_account,
        amount_cents: 1_000,
        description: "Capture auction hold"
      ).call

      expect(result.ledger_entry).to be_capture
      expect(result.ledger_entry.amount_cents).to eq(-1_000)
    end

    it "fails when held funds are insufficient" do
      result = described_class.new(
        financial_account: financial_account,
        amount_cents: 5_000,
        description: "Capture auction hold"
      ).call

      expect(result).not_to be_success
      expect(result.error).to include("Insufficient held funds")
    end
  end
end
