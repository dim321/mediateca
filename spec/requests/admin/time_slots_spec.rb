require "rails_helper"

RSpec.describe "Admin::TimeSlots", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:html_headers) { { "Accept" => "text/html" } }
  let(:admin) { create(:user, :admin) }
  let(:device) { create(:broadcast_device, time_zone: "Moscow") }

  before { sign_in admin }

  describe "GET /admin/devices/:device_id/time_slots" do
    let!(:slot) { create(:time_slot, broadcast_device: device) }

    it "returns schedule for device" do
      get admin_device_time_slots_path(device), headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "shows slots from the device local day even when they fall on the previous UTC date" do
      date = Date.new(2026, 3, 26)
      zone = ActiveSupport::TimeZone[device.time_zone]
      local_midnight = zone.local(date.year, date.month, date.day)

      create(
        :time_slot,
        broadcast_device: device,
        start_time: local_midnight.utc,
        end_time: (local_midnight + 30.minutes).utc,
        starting_price: 321.00
      )

      get admin_device_time_slots_path(device, date: date.to_s), headers: html_headers

      expect(response.body).to include("00:00 — 00:30")
      expect(response.body).to include("321,00 ₽")
    end

    it "defaults to the device local date when date is omitted" do
      device.update!(time_zone: "Pacific/Kiritimati")
      travel_to Time.utc(2026, 3, 25, 11, 30) do
        date = Date.new(2026, 3, 26)
        zone = ActiveSupport::TimeZone[device.time_zone]
        local_midnight = zone.local(date.year, date.month, date.day)

        create(
          :time_slot,
          broadcast_device: device,
          start_time: local_midnight.utc,
          end_time: (local_midnight + 30.minutes).utc
        )

        get admin_device_time_slots_path(device), headers: html_headers

        expect(response.body).to include("00:00 — 00:30")
      end
    end
  end

  describe "POST /admin/devices/:device_id/time_slots/generate" do
    it "generates 48 slots for a given date" do
      expect {
        post generate_admin_device_time_slots_path(device),
             params: { date: 1.week.from_now.to_date.to_s },
             headers: html_headers
      }.to change(TimeSlot, :count).by(48)
    end

    it "generates the exact number of half-hour slots in a device local DST day" do
      device.update!(time_zone: "Eastern Time (US & Canada)")
      date = Date.new(2026, 3, 8)
      zone = ActiveSupport::TimeZone[device.time_zone]

      expect {
        post generate_admin_device_time_slots_path(device),
             params: { date: date.to_s },
             headers: html_headers
      }.to change(TimeSlot, :count).by(46)

      generated_slots = device.time_slots.for_date(date, zone).order(start_time: :asc)
      expect(generated_slots.size).to eq(46)
      expect(generated_slots.first.display_time_in_zone).to eq("00:00 — 00:30")
      expect(generated_slots.last.end_time).to eq(zone.local(2026, 3, 9).utc)
    end

    it "generates the repeated hour on a device local DST fall-back day" do
      device.update!(time_zone: "Eastern Time (US & Canada)")
      date = Date.new(2026, 11, 1)
      zone = ActiveSupport::TimeZone[device.time_zone]

      expect {
        post generate_admin_device_time_slots_path(device),
             params: { date: date.to_s },
             headers: html_headers
      }.to change(TimeSlot, :count).by(50)

      generated_slots = device.time_slots.for_date(date, zone).order(start_time: :asc)
      expect(generated_slots.size).to eq(50)
      expect(generated_slots.first.display_time_in_zone).to eq("00:00 — 00:30")
      expect(generated_slots.last.end_time).to eq(zone.local(2026, 11, 2).utc)
    end

    it "defaults generation to the device local date when date is omitted" do
      device.update!(time_zone: "Pacific/Kiritimati")
      travel_to Time.utc(2026, 3, 25, 11, 30) do
        date = Date.new(2026, 3, 26)
        zone = ActiveSupport::TimeZone[device.time_zone]

        expect {
          post generate_admin_device_time_slots_path(device), headers: html_headers
        }.to change(TimeSlot, :count).by(48)

        expect(device.time_slots.for_date(date, zone).count).to eq(48)
        expect(response).to redirect_to(admin_device_time_slots_path(device, date: date))
      end
    end

    it "rejects duplicate date generation" do
      target_date = 1.week.from_now.to_date.to_s
      post generate_admin_device_time_slots_path(device), params: { date: target_date }, headers: html_headers
      expect {
        post generate_admin_device_time_slots_path(device), params: { date: target_date }, headers: html_headers
      }.not_to change(TimeSlot, :count)
    end
  end

  describe "PATCH /admin/time_slots/:id" do
    let(:slot) { create(:time_slot, broadcast_device: device, starting_price: 100) }

    it "updates starting_price" do
      patch admin_time_slot_path(slot), params: { time_slot: { starting_price: 250 } }, headers: html_headers
      expect(slot.reload.starting_price.to_f).to eq(250.0)
    end
  end
end
