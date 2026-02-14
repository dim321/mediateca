FactoryBot.define do
  factory :device_group do
    name { Faker::Commerce.department(max: 1) + " #{SecureRandom.hex(4)}" }
    description { Faker::Lorem.sentence }
  end
end
