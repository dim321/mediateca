require "rails_helper"

RSpec.describe Billing::BalanceCheckService do
  let(:user) { create(:user, balance: 3000) }

  describe "#call" do
    it "returns true for sufficient balance" do
      result = described_class.new(user: user, required_amount: 2000).call
      expect(result).to be_sufficient
    end

    it "returns false for insufficient balance" do
      result = described_class.new(user: user, required_amount: 5000).call
      expect(result).not_to be_sufficient
      expect(result.deficit.to_f).to eq(2000.0)
    end

    it "returns current_balance" do
      result = described_class.new(user: user, required_amount: 1000).call
      expect(result.current_balance.to_f).to eq(3000.0)
    end
  end
end
