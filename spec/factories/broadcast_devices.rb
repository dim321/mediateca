FactoryBot.define do
  factory :broadcast_device do
    name { Faker::Device.model_name }
    city { Faker::Address.city }
    address { Faker::Address.street_address }
    time_zone { "Moscow" }
    status { :offline }
    description { Faker::Lorem.sentence }

    trait :online do
      status { :online }
      last_heartbeat_at { 1.minute.ago }
    end

    trait :offline do
      status { :offline }
    end
  end
end
