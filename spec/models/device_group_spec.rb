require "rails_helper"

RSpec.describe DeviceGroup, type: :model do
  subject(:group) { build(:device_group) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "associations" do
    it { is_expected.to have_many(:device_group_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:broadcast_devices).through(:device_group_memberships) }
  end

  describe "counter_cache" do
    let(:group) { create(:device_group) }
    let(:device) { create(:broadcast_device) }

    it "increments devices_count when membership created" do
      expect {
        create(:device_group_membership, device_group: group, broadcast_device: device)
      }.to change { group.reload.devices_count }.by(1)
    end

    it "decrements devices_count when membership destroyed" do
      membership = create(:device_group_membership, device_group: group, broadcast_device: device)
      expect {
        membership.destroy
      }.to change { group.reload.devices_count }.by(-1)
    end
  end
end
