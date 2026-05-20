require "rails_helper"

RSpec.describe "Devices", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:html_headers) { { "Accept" => "text/html" } }
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /devices" do
    let!(:device1) { create(:broadcast_device, city: "Москва", status: :online) }
    let!(:device2) { create(:broadcast_device, city: "Санкт-Петербург", status: :online) }

    it "returns list of devices" do
      get devices_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "filters by city" do
      get devices_path(city: "Москва"), headers: html_headers
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(device1.name)
    end
  end

  describe "GET /devices/:id/schedule" do
    let(:device) { create(:broadcast_device) }
    let!(:slot) { create(:time_slot, broadcast_device: device) }

    it "returns schedule for the device" do
      get schedule_device_path(device), headers: html_headers
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
        end_time: (local_midnight + 30.minutes).utc
      )

      get schedule_device_path(device, date: date.to_s), headers: html_headers

      expect(response.body).to include("00:00 — 00:30")
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

        get schedule_device_path(device), headers: html_headers

        expect(response.body).to include("00:00 — 00:30")
      end
    end
  end
end
