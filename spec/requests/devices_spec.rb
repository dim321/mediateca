require "rails_helper"

RSpec.describe "Devices", type: :request do
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
    let(:device) { create(:broadcast_device, time_zone: "Moscow") }
    let!(:slot) { create(:time_slot, broadcast_device: device) }

    it "returns schedule for the device" do
      get schedule_device_path(device), headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "shows slots for the selected date in the device time zone" do
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

      get schedule_device_path(device, date: "2026-05-10"), headers: html_headers

      expect(response.body).to include("00:00")
      expect(response.body).to include("23:30")
    end
  end
end
