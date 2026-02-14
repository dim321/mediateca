require "rails_helper"

RSpec.describe "Admin::Devices", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before { sign_in admin }

  describe "GET /admin/devices" do
    let!(:device1) { create(:broadcast_device, city: "Москва") }
    let!(:device2) { create(:broadcast_device, city: "Санкт-Петербург") }

    it "returns list of devices" do
      get admin_devices_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "denies access to non-admin users" do
      sign_in regular_user
      get admin_devices_path, headers: html_headers
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/devices" do
    let(:valid_params) do
      {
        broadcast_device: {
          name: "ТВ Зал 1",
          city: "Москва",
          address: "ул. Тверская, 1",
          time_zone: "Moscow",
          description: "Основной зал"
        }
      }
    end

    it "creates a device with valid data" do
      expect {
        post admin_devices_path, params: valid_params, headers: html_headers
      }.to change(BroadcastDevice, :count).by(1)
    end

    it "generates an api_token automatically" do
      post admin_devices_path, params: valid_params, headers: html_headers
      expect(BroadcastDevice.last.api_token).to be_present
    end

    it "rejects device without required fields" do
      expect {
        post admin_devices_path, params: { broadcast_device: { name: "" } }, headers: html_headers
      }.not_to change(BroadcastDevice, :count)
    end
  end

  describe "PATCH /admin/devices/:id" do
    let(:device) { create(:broadcast_device) }

    it "updates device attributes" do
      patch admin_device_path(device), params: { broadcast_device: { name: "New Name" } }, headers: html_headers
      expect(device.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /admin/devices/:id" do
    let!(:device) { create(:broadcast_device) }

    it "deletes the device" do
      expect {
        delete admin_device_path(device), headers: html_headers
      }.to change(BroadcastDevice, :count).by(-1)
    end
  end
end
