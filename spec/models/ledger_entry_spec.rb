require "rails_helper"

RSpec.describe LedgerEntry, type: :model do
  subject(:ledger_entry) { build(:ledger_entry) }

  describe "associations" do
    it { is_expected.to belong_to(:financial_account) }
    it { is_expected.to belong_to(:payment).optional }
    it { is_expected.to belong_to(:reference).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_numericality_of(:amount_cents).only_integer }
    it { is_expected.to validate_numericality_of(:balance_after_cents).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:held_after_cents).only_integer.is_greater_than_or_equal_to(0) }

    it "does not allow zero amount_cents" do
      ledger_entry.amount_cents = 0
      expect(ledger_entry).not_to be_valid
      expect(ledger_entry.errors[:amount_cents]).to be_present
    end
  end

  describe "enums" do
    it do
      is_expected.to define_enum_for(:entry_type).with_values(
        deposit_settled: 0,
        hold: 1,
        release: 2,
        capture: 3,
        refund: 4,
        adjustment: 5
      )
    end
  end

  describe "immutability" do
    let(:saved_ledger_entry) { create(:ledger_entry) }

    it "raises on update" do
      expect {
        saved_ledger_entry.update!(description: "Updated")
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises on destroy" do
      expect {
        saved_ledger_entry.destroy!
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises on destroy without bang" do
      expect {
        saved_ledger_entry.destroy
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
