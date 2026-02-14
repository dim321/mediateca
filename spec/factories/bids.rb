FactoryBot.define do
  factory :bid do
    auction
    user
    amount { 500.00 }
  end
end
