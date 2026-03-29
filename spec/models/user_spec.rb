require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(user: 0, admin: 1) }
  end

  describe "associations" do
    # Associations are tested once their target models exist (US1-US6)
    it { is_expected.to have_one(:financial_account).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:media_files).dependent(:destroy) }
    it { is_expected.to have_many(:playlists).dependent(:destroy) }
    it { is_expected.to have_many(:bids).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:payments).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:transactions).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:scheduled_broadcasts).dependent(:restrict_with_error) }

    it "declares associations for future models" do
      has_many_associations = User.reflect_on_all_associations(:has_many).map(&:name)
      has_one_associations = User.reflect_on_all_associations(:has_one).map(&:name)

      expect(has_one_associations).to include(:financial_account)
      expect(has_many_associations).to include(:media_files, :playlists, :bids, :payments, :transactions, :scheduled_broadcasts)
    end
  end

  describe "Devise" do
    it "is database authenticatable" do
      expect(user).to respond_to(:email, :encrypted_password)
    end

    it "is registerable" do
      expect(User.devise_modules).to include(:registerable)
    end

    it "is recoverable" do
      expect(user).to respond_to(:reset_password_token)
    end

    it "is rememberable" do
      expect(user).to respond_to(:remember_created_at)
    end
  end

  describe "roles" do
    it "defaults to user role" do
      new_user = User.new
      expect(new_user.role).to eq("user")
    end

    it "can be set to admin" do
      user.role = :admin
      expect(user).to be_admin
    end

    it "identifies admin users" do
      admin = build(:user, :admin)
      expect(admin).to be_admin
    end
  end

  describe "#full_name" do
    it "returns first and last name" do
      user = build(:user, first_name: "Ivan", last_name: "Petrov")
      expect(user.full_name).to eq("Ivan Petrov")
    end
  end

  describe "#financial_account!" do
    it "creates a financial account when missing" do
      user = create(:user)

      expect {
        user.financial_account!
      }.to change(FinancialAccount, :count).by(1)
    end

    it "returns the existing financial account" do
      user = create(:user)
      existing_account = create(:financial_account, user: user)

      expect(user.financial_account!).to eq(existing_account)
    end

    it "returns the existing account when a creation race raises RecordNotUnique" do
      user = create(:user)
      existing_account = create(:financial_account, user: user)

      allow(user).to receive(:financial_account).and_return(nil, existing_account)
      allow(user).to receive(:create_financial_account!).with(currency: "RUB").and_raise(ActiveRecord::RecordNotUnique)

      expect(user.financial_account!).to eq(existing_account)
    end
  end
end
