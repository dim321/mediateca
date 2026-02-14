FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    role { :user }
    balance { 0 }

    trait :admin do
      role { :admin }
    end

    trait :with_balance do
      balance { 10_000.00 }
    end

    trait :with_company do
      company_name { Faker::Company.name }
    end
  end
end
