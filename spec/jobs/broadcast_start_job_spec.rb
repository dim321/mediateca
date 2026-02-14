require "rails_helper"

RSpec.describe BroadcastStartJob, type: :job do
  let(:broadcast) { create(:scheduled_broadcast) }
  let(:device) { broadcast.time_slot.broadcast_device }

  describe "#perform" do
    it "is enqueued in broadcasts queue" do
      expect {
        described_class.perform_later(broadcast.id)
      }.to have_enqueued_job(described_class).on_queue("broadcasts")
    end

    context "when device is online" do
      before { device.update!(status: :online) }

      it "updates broadcast status to playing" do
        described_class.perform_now(broadcast.id)
        expect(broadcast.reload).to be_playing
      end

      it "sets started_at" do
        described_class.perform_now(broadcast.id)
        expect(broadcast.reload.started_at).to be_present
      end
    end

    context "when device is offline" do
      before { device.update!(status: :offline) }

      it "updates broadcast status to failed" do
        described_class.perform_now(broadcast.id)
        expect(broadcast.reload).to be_failed
      end
    end

    context "when broadcast is not in scheduled state" do
      before { broadcast.update!(broadcast_status: :completed, started_at: 1.hour.ago, completed_at: Time.current) }

      it "does not change the status" do
        described_class.perform_now(broadcast.id)
        expect(broadcast.reload).to be_completed
      end
    end
  end
end
