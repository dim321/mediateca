require "rails_helper"

RSpec.describe TimeSlot, type: :model do
  subject(:time_slot) { build(:time_slot) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:start_time) }
    it { is_expected.to validate_presence_of(:end_time) }
    it { is_expected.to validate_numericality_of(:starting_price).is_greater_than_or_equal_to(0) }

    it "validates end_time is after start_time" do
      time_slot.end_time = time_slot.start_time - 1.hour
      expect(time_slot).not_to be_valid
    end

    it "validates 30-minute duration" do
      time_slot.end_time = time_slot.start_time + 45.minutes
      expect(time_slot).not_to be_valid
    end

    it "validates uniqueness of device + start_time" do
      existing = create(:time_slot)
      duplicate = build(:time_slot, broadcast_device: existing.broadcast_device, start_time: existing.start_time, end_time: existing.end_time)
      expect(duplicate).not_to be_valid
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:slot_status).with_values(available: 0, auction_active: 1, sold: 2) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:broadcast_device) }
  end

  describe "scopes" do
    let(:device) { create(:broadcast_device) }
    let!(:available_slot) { create(:time_slot, :available, broadcast_device: device) }
    let!(:sold_slot) { create(:time_slot, :sold, broadcast_device: device, start_time: 2.days.from_now.beginning_of_hour, end_time: 2.days.from_now.beginning_of_hour + 30.minutes) }

    it "filters available slots" do
      expect(described_class.available).to include(available_slot)
      expect(described_class.available).not_to include(sold_slot)
    end
  end

  describe ".for_date" do
    let(:device) { create(:broadcast_device, time_zone: "Moscow") }
    let!(:previous_day_slot) do
      create(
        :time_slot,
        broadcast_device: device,
        start_time: Time.zone.parse("2026-05-09 20:30:00 UTC"),
        end_time: Time.zone.parse("2026-05-09 21:00:00 UTC")
      )
    end
    let!(:first_slot) do
      create(
        :time_slot,
        broadcast_device: device,
        start_time: Time.zone.parse("2026-05-09 21:00:00 UTC"),
        end_time: Time.zone.parse("2026-05-09 21:30:00 UTC")
      )
    end
    let!(:last_slot) do
      create(
        :time_slot,
        broadcast_device: device,
        start_time: Time.zone.parse("2026-05-10 20:30:00 UTC"),
        end_time: Time.zone.parse("2026-05-10 21:00:00 UTC")
      )
    end
    let!(:next_day_slot) do
      create(
        :time_slot,
        broadcast_device: device,
        start_time: Time.zone.parse("2026-05-10 21:00:00 UTC"),
        end_time: Time.zone.parse("2026-05-10 21:30:00 UTC")
      )
    end

    it "filters by the provided time zone's local day" do
      slots = device.time_slots.for_date("2026-05-10", "Moscow")

      expect(slots).to contain_exactly(first_slot, last_slot)
      expect(slots).not_to include(previous_day_slot, next_day_slot)
    end
  end
end
