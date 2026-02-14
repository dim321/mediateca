require "rails_helper"

RSpec.describe PlaylistPolicy, type: :policy do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:playlist) { create(:playlist, user: owner) }

  describe "permissions" do
    context "for the owner" do
      subject { described_class.new(owner, playlist) }

      it "permits show" do
        expect(subject.show?).to be true
      end

      it "permits create" do
        expect(subject.create?).to be true
      end

      it "permits update" do
        expect(subject.update?).to be true
      end

      it "permits destroy" do
        expect(subject.destroy?).to be true
      end
    end

    context "for a non-owner" do
      subject { described_class.new(other_user, playlist) }

      it "forbids show" do
        expect(subject.show?).to be false
      end

      it "forbids update" do
        expect(subject.update?).to be false
      end

      it "forbids destroy" do
        expect(subject.destroy?).to be false
      end
    end
  end

  describe "Scope" do
    let!(:owner_playlist) { create(:playlist, user: owner) }
    let!(:other_playlist) { create(:playlist, user: other_user) }

    it "returns only owner's playlists" do
      scope = described_class::Scope.new(owner, Playlist.all).resolve
      expect(scope).to include(owner_playlist)
      expect(scope).not_to include(other_playlist)
    end
  end
end
