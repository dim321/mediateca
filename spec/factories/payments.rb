FactoryBot.define do
  factory :payment do
    user
    financial_account { association :financial_account, user: user }
    provider { :stripe }
    operation_type { :top_up }
    status { :pending }
    amount_cents { 1_000 }
    currency { "RUB" }
    idempotency_key { SecureRandom.uuid }
    metadata { {} }
    raw_response { {} }
  end
end
