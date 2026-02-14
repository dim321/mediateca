require "rails_helper"

RSpec.describe AuctionPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:auction) { create(:auction) }

  subject { described_class.new(user, auction) }

  it "allows index" do
    expect(subject.index?).to be true
  end

  it "allows show" do
    expect(subject.show?).to be true
  end
end
