require "rails_helper"

RSpec.describe Billing::DeductionService do
  let(:user) { create(:user, balance: 5000) }

  describe "#call" do
    context "with sufficient balance" do
      it "creates a deduction transaction" do
        expect {
          described_class.new(user: user, amount: 1500, description: "Аукцион #1").call
        }.to change(Transaction, :count).by(1)
      end

      it "deducts from user balance" do
        described_class.new(user: user, amount: 1500, description: "Аукцион #1").call
        expect(user.reload.balance.to_f).to eq(3500.0)
      end

      it "returns successful result" do
        result = described_class.new(user: user, amount: 1500, description: "Аукцион #1").call
        expect(result).to be_success
      end

      it "creates transaction with negative amount" do
        result = described_class.new(user: user, amount: 1500, description: "Аукцион #1").call
        expect(result.transaction.amount.to_f).to eq(-1500.0)
      end
    end

    context "with insufficient balance" do
      it "returns failure" do
        result = described_class.new(user: user, amount: 10000, description: "Аукцион #1").call
        expect(result).not_to be_success
        expect(result.error).to include("Недостаточно средств")
      end

      it "does not change balance" do
        described_class.new(user: user, amount: 10000, description: "Аукцион #1").call
        expect(user.reload.balance.to_f).to eq(5000.0)
      end

      it "does not create a transaction" do
        expect {
          described_class.new(user: user, amount: 10000, description: "Аукцион #1").call
        }.not_to change(Transaction, :count)
      end
    end
  end
end
