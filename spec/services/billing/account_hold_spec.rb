require "rails_helper"

RSpec.describe Billing::AccountHold do
  let(:financial_account) { create(:financial_account, available_amount_cents: 5_000, held_amount_cents: 0) }

  describe "#call" do
    it "moves funds from available to held" do
      described_class.new(
        financial_account: financial_account,
        amount_cents: 1_500,
        description: "Hold for auction"
      ).call

      financial_account.reload
      expect(financial_account.available_amount_cents).to eq(3_500)
      expect(financial_account.held_amount_cents).to eq(1_500)
    end

    it "creates a hold ledger entry" do
      result = described_class.new(
        financial_account: financial_account,
        amount_cents: 1_500,
        description: "Hold for auction"
      ).call

      expect(result.ledger_entry).to be_hold
      expect(result.ledger_entry.amount_cents).to eq(-1_500)
    end

    it "fails when available funds are insufficient" do
      result = described_class.new(
        financial_account: financial_account,
        amount_cents: 10_000,
        description: "Hold for auction"
      ).call

      expect(result).not_to be_success
      expect(result.error).to include("Insufficient available funds")
      expect(financial_account.reload.available_amount_cents).to eq(5_000)
    end

    it "is idempotent by key" do
      service = described_class.new(
        financial_account: financial_account,
        amount_cents: 1_500,
        description: "Hold for auction",
        idempotency_key: "hold-1"
      )

      first_result = service.call
      second_result = service.call

      expect(first_result).to be_success
      expect(second_result).to be_success
      expect(second_result).to be_idempotent
      expect(financial_account.reload.available_amount_cents).to eq(3_500)
      expect(financial_account.held_amount_cents).to eq(1_500)
    end

    it "mutates the account under a lock" do
      expect(financial_account).to receive(:with_lock).and_call_original

      described_class.new(
        financial_account: financial_account,
        amount_cents: 1_500,
        description: "Hold for auction"
      ).call
    end
  end
end
