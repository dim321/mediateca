require "rails_helper"

RSpec.describe Billing::AccountBalanceCheck do
  let(:financial_account) { create(:financial_account, available_amount_cents: 3_000, held_amount_cents: 0) }

  describe "#call" do
    it "returns true for sufficient balance" do
      result = described_class.new(financial_account: financial_account, required_amount_cents: 2_000).call

      expect(result).to be_sufficient
      expect(result.current_balance_cents).to eq(3_000)
      expect(result.deficit_cents).to eq(0)
    end

    it "returns false for insufficient balance" do
      result = described_class.new(financial_account: financial_account, required_amount_cents: 5_000).call

      expect(result).not_to be_sufficient
      expect(result.deficit_cents).to eq(2_000)
      expect(result.deficit).to eq(BigDecimal("20.0"))
    end

    it "returns current balance as decimal amount" do
      result = described_class.new(financial_account: financial_account, required_amount_cents: 1_000).call

      expect(result.current_balance).to eq(BigDecimal("30.0"))
    end
  end
end
