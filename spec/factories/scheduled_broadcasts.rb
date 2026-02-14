FactoryBot.define do
  factory :scheduled_broadcast do
    user
    playlist
    time_slot
    broadcast_status { :scheduled }

    trait :scheduled do
      broadcast_status { :scheduled }
    end

    trait :playing do
      broadcast_status { :playing }
      started_at { Time.current }
    end

    trait :completed do
      broadcast_status { :completed }
      started_at { 30.minutes.ago }
      completed_at { Time.current }
    end

    trait :failed do
      broadcast_status { :failed }
      started_at { 30.minutes.ago }
      completed_at { Time.current }
    end
  end
end
