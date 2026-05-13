require "rails_helper"

RSpec.describe "Api::V1::Device", type: :request do
  let(:device) { create(:broadcast_device, :online, time_zone: "Moscow") }
  let(:auth_headers) { { "Authorization" => "Bearer #{device.api_token}" } }

  describe "GET /api/v1/device/schedule" do
    it "returns schedule with valid token" do
      create(:time_slot, broadcast_device: device)

      get api_v1_device_schedule_path, headers: auth_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["time_slots"]).to be_an(Array)
    end

    it "returns slots for the selected date in the device time zone" do
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

      get api_v1_device_schedule_path(date: "2026-05-10"), headers: auth_headers

      json = JSON.parse(response.body)
      expect(json["time_slots"].size).to eq(2)
      expect(json["time_slots"].pluck("start_time").map { |start_time| Time.iso8601(start_time).utc }).to contain_exactly(
        Time.utc(2026, 5, 9, 21, 0),
        Time.utc(2026, 5, 10, 20, 30)
      )
    end

    it "rejects invalid token" do
      get api_v1_device_schedule_path, headers: { "Authorization" => "Bearer invalid" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects missing token" do
      get api_v1_device_schedule_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/device/heartbeat" do
    it "updates device status" do
      post api_v1_device_heartbeat_path, headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(device.reload.last_heartbeat_at).to be_present
    end

    it "rejects invalid token" do
      post api_v1_device_heartbeat_path, headers: { "Authorization" => "Bearer invalid" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/device/broadcast_status" do
    let(:broadcast) { create(:scheduled_broadcast, time_slot: create(:time_slot, broadcast_device: device)) }

    it "updates broadcast status to playing" do
      post api_v1_device_broadcast_status_path,
           params: { broadcast_id: broadcast.id, status: "playing" },
           headers: auth_headers,
           as: :json
      expect(response).to have_http_status(:ok)
      expect(broadcast.reload).to be_playing
    end

    it "updates broadcast status to completed" do
      broadcast.update!(broadcast_status: :playing, started_at: 30.minutes.ago)
      post api_v1_device_broadcast_status_path,
           params: { broadcast_id: broadcast.id, status: "completed" },
           headers: auth_headers,
           as: :json
      expect(response).to have_http_status(:ok)
      expect(broadcast.reload).to be_completed
    end

    it "updates broadcast status to failed" do
      post api_v1_device_broadcast_status_path,
           params: { broadcast_id: broadcast.id, status: "failed" },
           headers: auth_headers,
           as: :json
      expect(response).to have_http_status(:ok)
      expect(broadcast.reload).to be_failed
    end
  end
end
