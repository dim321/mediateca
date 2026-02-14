FactoryBot.define do
  factory :transaction do
    user
    amount { 1000.00 }
    transaction_type { :deposit }
    description { "Пополнение баланса" }

    trait :deposit do
      transaction_type { :deposit }
      amount { 5000.00 }
      description { "Пополнение баланса" }
    end

    trait :deduction do
      transaction_type { :deduction }
      amount { -1500.00 }
      description { "Списание за аукцион" }
    end
  end
end
