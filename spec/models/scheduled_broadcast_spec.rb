require "rails_helper"

RSpec.describe ScheduledBroadcast, type: :model do
  subject(:broadcast) { build(:scheduled_broadcast) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:broadcast_status) }

    it "validates uniqueness of time_slot_id" do
      create(:scheduled_broadcast)
      expect(build(:scheduled_broadcast, time_slot: ScheduledBroadcast.last.time_slot))
        .not_to be_valid
    end

    it "validates playlist duration does not exceed slot duration" do
      playlist = create(:playlist, total_duration: 1801)
      time_slot = create(:time_slot)
      sb = build(:scheduled_broadcast, playlist: playlist, time_slot: time_slot)
      expect(sb).not_to be_valid
      expect(sb.errors[:playlist]).to be_present
    end

    it "allows playlist duration equal to slot duration" do
      playlist = create(:playlist, total_duration: 1800) # 30 minutes
      time_slot = create(:time_slot)
      sb = build(:scheduled_broadcast, playlist: playlist, time_slot: time_slot)
      expect(sb).to be_valid
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:broadcast_status).with_values(scheduled: 0, playing: 1, completed: 2, failed: 3) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:playlist) }
    it { is_expected.to belong_to(:time_slot) }
  end

  describe "state transitions" do
    let(:broadcast) { create(:scheduled_broadcast) }

    it "can transition from scheduled to playing" do
      broadcast.update!(broadcast_status: :playing, started_at: Time.current)
      expect(broadcast).to be_playing
    end

    it "can transition from playing to completed" do
      broadcast.update!(broadcast_status: :playing, started_at: Time.current)
      broadcast.update!(broadcast_status: :completed, completed_at: Time.current)
      expect(broadcast).to be_completed
    end

    it "can transition from playing to failed" do
      broadcast.update!(broadcast_status: :playing, started_at: Time.current)
      broadcast.update!(broadcast_status: :failed, completed_at: Time.current)
      expect(broadcast).to be_failed
    end
  end
end
