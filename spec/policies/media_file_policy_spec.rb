require "rails_helper"

RSpec.describe MediaFilePolicy, type: :policy do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:media_file) { create(:media_file, user: owner) }

  describe "permissions" do
    context "for the owner" do
      subject { described_class.new(owner, media_file) }

      it "permits show" do
        expect(subject.show?).to be true
      end

      it "permits create" do
        expect(subject.create?).to be true
      end

      it "permits destroy" do
        expect(subject.destroy?).to be true
      end
    end

    context "for a non-owner" do
      subject { described_class.new(other_user, media_file) }

      it "forbids show" do
        expect(subject.show?).to be false
      end

      it "forbids destroy" do
        expect(subject.destroy?).to be false
      end
    end

    context "for an admin" do
      subject { described_class.new(admin, media_file) }

      it "cannot access other users' files" do
        expect(subject.show?).to be false
      end
    end
  end

  describe "Scope" do
    let!(:owner_file) { create(:media_file, user: owner) }
    let!(:other_file) { create(:media_file, user: other_user) }

    it "returns only owner's files" do
      scope = described_class::Scope.new(owner, MediaFile.all).resolve
      expect(scope).to include(owner_file)
      expect(scope).not_to include(other_file)
    end
  end
end
