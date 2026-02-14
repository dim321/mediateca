FactoryBot.define do
  factory :device_group_membership do
    broadcast_device
    device_group
  end
end
