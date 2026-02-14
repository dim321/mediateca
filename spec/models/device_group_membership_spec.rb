require "rails_helper"

RSpec.describe DeviceGroupMembership, type: :model do
  subject(:membership) { build(:device_group_membership) }

  describe "validations" do
    it "validates uniqueness of device within group" do
      existing = create(:device_group_membership)
      duplicate = build(:device_group_membership,
        broadcast_device: existing.broadcast_device,
        device_group: existing.device_group)
      expect(duplicate).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:broadcast_device) }
    it { is_expected.to belong_to(:device_group) }
  end
end
