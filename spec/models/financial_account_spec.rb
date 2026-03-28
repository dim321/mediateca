require "rails_helper"

RSpec.describe FinancialAccount, type: :model do
  subject(:financial_account) { build(:financial_account) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:ledger_entries).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:payments).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it "does not allow duplicate accounts for the same user" do
      existing_account = create(:financial_account)
      duplicate_account = build(:financial_account, user: existing_account.user)

      expect(duplicate_account).not_to be_valid
      expect(duplicate_account.errors[:user]).to be_present
    end

    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_numericality_of(:available_amount_cents).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:held_amount_cents).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, suspended: 1, closed: 2) }
  end

  describe "amount helpers" do
    subject(:account) { build(:financial_account, available_amount_cents: 12_345, held_amount_cents: 500) }

    it "converts available cents into decimal amount" do
      expect(account.available_amount).to eq(BigDecimal("123.45"))
    end

    it "converts held cents into decimal amount" do
      expect(account.held_amount).to eq(BigDecimal("5.0"))
    end

    it "calculates total amount" do
      expect(account.total_amount).to eq(BigDecimal("128.45"))
    end

    it "treats nil cents as zero" do
      account.available_amount_cents = nil

      expect(account.available_amount).to eq(BigDecimal("0"))
    end
  end
end
