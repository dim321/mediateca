FactoryBot.define do
  factory :playlist do
    user
    name { Faker::Music.album }
    description { Faker::Lorem.sentence }
    total_duration { 0 }
  end
end
