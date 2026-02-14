require "rails_helper"

RSpec.describe Broadcasts::ScheduleService do
  let(:user) { create(:user) }
  let(:device) { create(:broadcast_device) }
  let(:time_slot) { create(:time_slot, :available, broadcast_device: device) }
  let(:playlist) { create(:playlist, user: user, total_duration: 1500) }

  subject(:service) { described_class.new(user: user, playlist: playlist, time_slot: time_slot) }

  describe "#call" do
    context "when successful" do
      it "creates a scheduled broadcast" do
        expect { service.call }.to change(ScheduledBroadcast, :count).by(1)
      end

      it "returns a successful result" do
        result = service.call
        expect(result).to be_success
        expect(result.broadcast).to be_a(ScheduledBroadcast)
      end

      it "sets broadcast status to scheduled" do
        result = service.call
        expect(result.broadcast).to be_scheduled
      end

      it "updates time slot status to sold" do
        service.call
        expect(time_slot.reload).to be_sold
      end
    end

    context "when playlist duration exceeds slot" do
      let(:playlist) { create(:playlist, user: user, total_duration: 2000) }

      it "returns failure" do
        result = service.call
        expect(result).not_to be_success
        expect(result.error).to include("длительность")
      end

      it "does not create a broadcast" do
        expect { service.call }.not_to change(ScheduledBroadcast, :count)
      end
    end

    context "when time slot is not available" do
      let(:time_slot) { create(:time_slot, :sold, broadcast_device: device) }

      it "returns failure" do
        result = service.call
        expect(result).not_to be_success
        expect(result.error).to include("недоступен")
      end
    end
  end
end
