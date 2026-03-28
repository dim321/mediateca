require "rails_helper"

RSpec.describe Billing::AccountCredit do
  let(:financial_account) { create(:financial_account, available_amount_cents: 1_000, held_amount_cents: 0) }

  describe "#call" do
    it "credits available balance" do
      described_class.new(
        financial_account: financial_account,
        amount_cents: 500,
        description: "Top-up"
      ).call

      expect(financial_account.reload.available_amount_cents).to eq(1_500)
    end

    it "creates a ledger entry" do
      expect {
        described_class.new(
          financial_account: financial_account,
          amount_cents: 500,
          description: "Top-up"
        ).call
      }.to change(LedgerEntry, :count).by(1)
    end

    it "is idempotent by key" do
      service = described_class.new(
        financial_account: financial_account,
        amount_cents: 500,
        description: "Top-up",
        idempotency_key: "credit-1"
      )

      first_result = service.call
      second_result = service.call

      expect(first_result).to be_success
      expect(second_result).to be_success
      expect(second_result).to be_idempotent
      expect(financial_account.reload.available_amount_cents).to eq(1_500)
      expect(LedgerEntry.where(idempotency_key: "credit-1").count).to eq(1)
    end

    it "mutates the account under a lock" do
      expect(financial_account).to receive(:with_lock).and_call_original

      described_class.new(
        financial_account: financial_account,
        amount_cents: 500,
        description: "Top-up"
      ).call
    end
  end
end
