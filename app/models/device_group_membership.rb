class DeviceGroupMembership < ApplicationRecord
  # === Associations ===
  belongs_to :broadcast_device
  belongs_to :device_group, counter_cache: :devices_count

  # === Validations ===
  validates :broadcast_device_id, uniqueness: { scope: :device_group_id }
end
