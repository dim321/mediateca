require "rails_helper"

RSpec.describe "Admin::DeviceGroups", type: :request do
  let(:html_headers) { { "Accept" => "text/html" } }
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  before { sign_in admin }

  describe "GET /admin/device_groups" do
    let!(:group) { create(:device_group) }

    it "returns list of groups" do
      get admin_device_groups_path, headers: html_headers
      expect(response).to have_http_status(:ok)
    end

    it "denies access to non-admin" do
      sign_in regular_user
      get admin_device_groups_path, headers: html_headers
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /admin/device_groups" do
    it "creates a group with valid data" do
      expect {
        post admin_device_groups_path, params: { device_group: { name: "Торговые центры", description: "Группа ТЦ" } }, headers: html_headers
      }.to change(DeviceGroup, :count).by(1)
    end

    it "rejects group without name" do
      expect {
        post admin_device_groups_path, params: { device_group: { name: "" } }, headers: html_headers
      }.not_to change(DeviceGroup, :count)
    end
  end

  describe "PATCH /admin/device_groups/:id" do
    let(:group) { create(:device_group) }

    it "updates group attributes" do
      patch admin_device_group_path(group), params: { device_group: { name: "Updated Name" } }, headers: html_headers
      expect(group.reload.name).to eq("Updated Name")
    end
  end

  describe "DELETE /admin/device_groups/:id" do
    let!(:group) { create(:device_group) }
    let!(:device) { create(:broadcast_device) }
    let!(:membership) { create(:device_group_membership, device_group: group, broadcast_device: device) }

    it "deletes the group" do
      expect {
        delete admin_device_group_path(group), headers: html_headers
      }.to change(DeviceGroup, :count).by(-1)
    end

    it "preserves devices after group deletion" do
      expect {
        delete admin_device_group_path(group), headers: html_headers
      }.not_to change(BroadcastDevice, :count)
    end
  end

  describe "POST /admin/device_groups/:id/add_devices" do
    let(:group) { create(:device_group) }
    let(:device1) { create(:broadcast_device) }
    let(:device2) { create(:broadcast_device) }

    it "adds devices to the group" do
      expect {
        post add_devices_admin_device_group_path(group),
             params: { device_ids: [device1.id, device2.id] },
             headers: html_headers
      }.to change(DeviceGroupMembership, :count).by(2)
    end
  end

  describe "DELETE /admin/device_groups/:id/remove_device/:device_id" do
    let(:group) { create(:device_group) }
    let(:device) { create(:broadcast_device) }
    let!(:membership) { create(:device_group_membership, device_group: group, broadcast_device: device) }

    it "removes device from group" do
      expect {
        delete remove_device_admin_device_group_path(group, device_id: device.id), headers: html_headers
      }.to change(DeviceGroupMembership, :count).by(-1)
    end

    it "preserves the device" do
      expect {
        delete remove_device_admin_device_group_path(group, device_id: device.id), headers: html_headers
      }.not_to change(BroadcastDevice, :count)
    end
  end
end
