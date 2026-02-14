require "rails_helper"

RSpec.describe BroadcastDevice, type: :model do
  subject(:device) { build(:broadcast_device) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:time_zone) }

    it "validates time_zone is a valid ActiveSupport::TimeZone" do
      device.time_zone = "Invalid/Zone"
      expect(device).not_to be_valid
      expect(device.errors[:time_zone]).to be_present
    end

    it "validates api_token uniqueness" do
      create(:broadcast_device)
      is_expected.to validate_uniqueness_of(:api_token)
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(offline: 0, online: 1) }
  end

  describe "associations" do
    it { is_expected.to have_many(:time_slots).dependent(:destroy) }
    it { is_expected.to have_many(:device_group_memberships).dependent(:destroy) }
    it { is_expected.to have_many(:device_groups).through(:device_group_memberships) }
  end

  describe "api_token auto-generation" do
    it "generates api_token on create" do
      device = create(:broadcast_device)
      expect(device.api_token).to be_present
      expect(device.api_token.length).to be >= 32
    end

    it "generates unique tokens" do
      d1 = create(:broadcast_device)
      d2 = create(:broadcast_device)
      expect(d1.api_token).not_to eq(d2.api_token)
    end
  end
end
