FactoryBot.define do
  factory :financial_account do
    user
    currency { "RUB" }
    available_amount_cents { 0 }
    held_amount_cents { 0 }
    status { :active }
  end
end
