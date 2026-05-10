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

    it "filters slots by the device local day" do
      moscow_device = create(:broadcast_device, time_zone: "Moscow")
      date = Date.new(2026, 5, 10)
      zone = ActiveSupport::TimeZone[moscow_device.time_zone]
      local_midnight = zone.local(date.year, date.month, date.day)
      first_slot = create(
        :time_slot,
        broadcast_device: moscow_device,
        start_time: local_midnight.utc,
        end_time: (local_midnight + 30.minutes).utc
      )
      last_slot = create(
        :time_slot,
        broadcast_device: moscow_device,
        start_time: (local_midnight + 23.hours + 30.minutes).utc,
        end_time: (local_midnight + 24.hours).utc
      )
      previous_day_slot = create(
        :time_slot,
        broadcast_device: moscow_device,
        start_time: (local_midnight - 30.minutes).utc,
        end_time: local_midnight.utc
      )

      result = described_class.for_date(date, moscow_device.time_zone)

      expect(result).to include(first_slot, last_slot)
      expect(result).not_to include(previous_day_slot)
    end
  end
end
