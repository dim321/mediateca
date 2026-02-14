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
    let(:device) { create(:broadcast_device) }
    let!(:slot) { create(:time_slot, broadcast_device: device) }

    it "returns schedule for the device" do
      get schedule_device_path(device), headers: html_headers
      expect(response).to have_http_status(:ok)
    end
  end
end
