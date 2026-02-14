require "rails_helper"

RSpec.describe Broadcasts::PlaybackService do
  let(:broadcast) { create(:scheduled_broadcast) }

  describe "#call" do
    context "when starting playback" do
      it "updates broadcast to playing" do
        described_class.new(broadcast: broadcast, status: "playing").call
        expect(broadcast.reload).to be_playing
        expect(broadcast.started_at).to be_present
      end
    end

    context "when completing playback" do
      before { broadcast.update!(broadcast_status: :playing, started_at: 30.minutes.ago) }

      it "updates broadcast to completed" do
        described_class.new(broadcast: broadcast, status: "completed").call
        expect(broadcast.reload).to be_completed
        expect(broadcast.completed_at).to be_present
      end
    end

    context "when playback fails" do
      it "updates broadcast to failed" do
        described_class.new(broadcast: broadcast, status: "failed").call
        expect(broadcast.reload).to be_failed
        expect(broadcast.completed_at).to be_present
      end
    end
  end
end
