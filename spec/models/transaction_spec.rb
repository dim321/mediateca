require "rails_helper"

RSpec.describe Transaction, type: :model do
  subject(:transaction) { build(:transaction) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:transaction_type) }
    it { is_expected.to validate_presence_of(:description) }

    it "validates amount is not zero" do
      transaction.amount = 0
      expect(transaction).not_to be_valid
      expect(transaction.errors[:amount]).to be_present
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:transaction_type).with_values(deposit: 0, deduction: 1) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "immutability" do
    let(:saved_transaction) { create(:transaction) }

    it "raises on update" do
      expect {
        saved_transaction.update!(amount: 9999)
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "raises on destroy" do
      expect {
        saved_transaction.destroy!
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
