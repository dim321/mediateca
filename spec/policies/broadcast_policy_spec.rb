require "rails_helper"

RSpec.describe ScheduledBroadcastPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:broadcast) { create(:scheduled_broadcast, user: user) }

  describe "owner" do
    subject { described_class.new(user, broadcast) }

    it "allows index" do
      expect(subject.index?).to be true
    end

    it "allows show" do
      expect(subject.show?).to be true
    end

    it "allows create" do
      expect(subject.create?).to be true
    end
  end

  describe "non-owner" do
    subject { described_class.new(other_user, broadcast) }

    it "allows index" do
      expect(subject.index?).to be true
    end

    it "denies show" do
      expect(subject.show?).to be false
    end
  end

  describe "scope" do
    let!(:my_broadcast) { create(:scheduled_broadcast, user: user) }
    let!(:other_broadcast) { create(:scheduled_broadcast, user: other_user) }

    it "resolves to user's broadcasts" do
      scope = described_class::Scope.new(user, ScheduledBroadcast.all).resolve
      expect(scope).to include(my_broadcast)
      expect(scope).not_to include(other_broadcast)
    end
  end
end
