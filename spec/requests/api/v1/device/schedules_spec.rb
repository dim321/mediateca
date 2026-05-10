require "rails_helper"

RSpec.describe "Api::V1::Device::Schedules", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  describe "GET /api/v1/device/schedule" do
    let(:device) { create(:broadcast_device, time_zone: "Moscow") }
    let(:headers) { { "Authorization" => "Bearer #{device.api_token}" } }
    let(:date) { Date.new(2026, 5, 10) }

    before do
      zone = ActiveSupport::TimeZone[device.time_zone]
      day_start = zone.local(date.year, date.month, date.day)

      48.times do |index|
        start_time = day_start + (index * 30).minutes
        create(
          :time_slot,
          broadcast_device: device,
          start_time: start_time.utc,
          end_time: (start_time + 30.minutes).utc
        )
      end
    end

    it "returns every slot from the device local day" do
      get api_v1_device_schedule_path, params: { date: date.to_s }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("time_slots").size).to eq(48)
    end

    it "defaults to the device local date when date is omitted" do
      travel_to Time.zone.local(2026, 5, 9, 22, 30) do
        get api_v1_device_schedule_path, headers: headers
      end

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).fetch("time_slots").size).to eq(48)
    end
  end
end
