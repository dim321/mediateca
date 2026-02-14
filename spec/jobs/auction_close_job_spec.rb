require "rails_helper"

RSpec.describe AuctionCloseJob, type: :job do
  let(:auction) { create(:auction, :open) }

  describe "#perform" do
    it "is enqueued in auctions queue" do
      expect {
        described_class.perform_later(auction.id)
      }.to have_enqueued_job(described_class).on_queue("auctions")
    end

    it "calls CloseAuctionService" do
      service = instance_double(Auctions::CloseAuctionService, call: Struct.new(:success?).new(true))
      allow(Auctions::CloseAuctionService).to receive(:new).and_return(service)

      described_class.perform_now(auction.id)

      expect(Auctions::CloseAuctionService).to have_received(:new).with(hash_including(auction: auction))
    end

    it "handles already-closed auction gracefully" do
      auction.update!(auction_status: :closed)
      expect { described_class.perform_now(auction.id) }.not_to raise_error
    end
  end
end
