require "rails_helper"

RSpec.describe Billing::DepositService do
  let(:user) { create(:user, balance: 1000) }

  describe "#call" do
    context "with valid amount" do
      it "creates a deposit transaction" do
        expect {
          described_class.new(user: user, amount: 500).call
        }.to change(Transaction, :count).by(1)
      end

      it "updates user balance" do
        described_class.new(user: user, amount: 500).call
        expect(user.reload.balance.to_f).to eq(1500.0)
      end

      it "returns successful result" do
        result = described_class.new(user: user, amount: 500).call
        expect(result).to be_success
        expect(result.transaction).to be_a(Transaction)
      end
    end

    context "with invalid amount" do
      it "rejects zero amount" do
        result = described_class.new(user: user, amount: 0).call
        expect(result).not_to be_success
        expect(result.error).to include("больше 0")
      end

      it "rejects negative amount" do
        result = described_class.new(user: user, amount: -100).call
        expect(result).not_to be_success
      end
    end
  end
end
