require "rails_helper"

RSpec.describe ApplicationPolicy, type: :policy do
  let(:user) { build(:user) }
  let(:admin) { build(:user, :admin) }
  let(:record) { double("record") }

  subject { described_class.new(user, record) }

  describe "default permissions" do
    it "denies index by default" do
      expect(subject.index?).to be false
    end

    it "denies show by default" do
      expect(subject.show?).to be false
    end

    it "denies create by default" do
      expect(subject.create?).to be false
    end

    it "denies update by default" do
      expect(subject.update?).to be false
    end

    it "denies destroy by default" do
      expect(subject.destroy?).to be false
    end
  end

  describe "admin check" do
    subject { described_class.new(admin, record) }

    it "identifies admin users" do
      expect(admin).to be_admin
    end
  end

  describe "Scope" do
    it "raises NotImplementedError by default" do
      scope = described_class::Scope.new(user, User.all)
      expect { scope.resolve }.to raise_error(NotImplementedError)
    end
  end
end
