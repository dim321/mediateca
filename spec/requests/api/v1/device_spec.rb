require "rails_helper"

RSpec.describe "Api::V1::Device", type: :request do
  let(:device) { create(:broadcast_device, :online) }
  let(:auth_headers) { { "Authorization" => "Bearer #{device.api_token}" } }

  describe "GET /api/v1/device/schedule" do
    let!(:slot) { create(:time_slot, broadcast_device: device) }

    it "returns schedule with valid token" do
      get api_v1_device_schedule_path, headers: auth_headers
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["time_slots"]).to be_an(Array)
    end

    it "returns slots for the device local day when it differs from the UTC day" do
      device.update!(time_zone: "Krasnoyarsk")
      zone = ActiveSupport::TimeZone["Krasnoyarsk"]
      local_day = Date.new(2026, 3, 27)
      local_midnight_slot = create(
        :time_slot,
        broadcast_device: device,
        start_time: zone.local(2026, 3, 27, 0, 0).utc,
        end_time: zone.local(2026, 3, 27, 0, 30).utc
      )
      previous_local_day_slot = create(
        :time_slot,
        broadcast_device: device,
        start_time: zone.local(2026, 3, 26, 23, 30).utc,
        end_time: zone.local(2026, 3, 27, 0, 0).utc
      )

      get api_v1_device_schedule_path,
          params: { date: local_day.to_s },
          headers: auth_headers

      slot_ids = JSON.parse(response.body).fetch("time_slots").map { |time_slot| time_slot.fetch("id") }
      expect(slot_ids).to include(local_midnight_slot.id)
      expect(slot_ids).not_to include(previous_local_day_slot.id)
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

    it "does not update broadcasts assigned to another device" do
      other_device = create(:broadcast_device)
      other_broadcast = create(:scheduled_broadcast, time_slot: create(:time_slot, broadcast_device: other_device))

      post api_v1_device_broadcast_status_path,
           params: { broadcast_id: other_broadcast.id, status: "playing" },
           headers: auth_headers,
           as: :json

      expect(response).to have_http_status(:not_found)
      expect(other_broadcast.reload).to be_scheduled
    end
  end
end
