class DeviceGroup < ApplicationRecord
  # === Associations ===
  has_many :device_group_memberships, dependent: :destroy
  has_many :broadcast_devices, through: :device_group_memberships

  # === Validations ===
  validates :name, presence: true, uniqueness: true
end
