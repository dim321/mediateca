FactoryBot.define do
  factory :time_slot do
    broadcast_device
    start_time { 1.day.from_now.beginning_of_hour }
    end_time { 1.day.from_now.beginning_of_hour + 30.minutes }
    starting_price { 100.00 }
    slot_status { :available }

    trait :available do
      slot_status { :available }
    end

    trait :auction_active do
      slot_status { :auction_active }
    end

    trait :sold do
      slot_status { :sold }
    end
  end
end
