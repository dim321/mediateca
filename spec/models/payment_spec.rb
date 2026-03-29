require "rails_helper"

RSpec.describe Payment, type: :model do
  subject(:payment) { build(:payment) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:financial_account) }
    it { is_expected.to have_many(:ledger_entries).dependent(:restrict_with_error) }
  end

  describe "validations" do
    it "does not allow duplicate idempotency keys" do
      existing_payment = create(:payment)
      duplicate_payment = build(:payment, idempotency_key: existing_payment.idempotency_key)

      expect(duplicate_payment).not_to be_valid
      expect(duplicate_payment.errors[:idempotency_key]).to be_present
    end

    it { is_expected.to validate_presence_of(:currency) }
    it { is_expected.to validate_presence_of(:idempotency_key) }
    it { is_expected.to validate_numericality_of(:amount_cents).only_integer.is_greater_than(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:provider).with_values(stripe: 0, yookassa: 1) }
    it { is_expected.to define_enum_for(:operation_type).with_values(top_up: 0, refund: 1) }

    it do
      is_expected.to define_enum_for(:status).with_values(
        pending: 0,
        requires_action: 1,
        processing: 2,
        succeeded: 3,
        failed: 4,
        canceled: 5
      )
    end
  end
end
