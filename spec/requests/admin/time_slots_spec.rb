require "rails_helper"

RSpec.describe "Admin::TimeSlots", type: :request do
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

    it "shows slots that belong to the selected date in the device time zone" do
      create(
        :time_slot,
        broadcast_device: device,
        start_time: Time.zone.parse("2026-05-09 21:00:00 UTC"),
        end_time: Time.zone.parse("2026-05-09 21:30:00 UTC")
      )
      create(
        :time_slot,
        broadcast_device: device,
        start_time: Time.zone.parse("2026-05-10 20:30:00 UTC"),
        end_time: Time.zone.parse("2026-05-10 21:00:00 UTC")
      )

      get admin_device_time_slots_path(device, date: "2026-05-10"), headers: html_headers

      expect(response.body).to include("00:00")
      expect(response.body).to include("23:30")
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
