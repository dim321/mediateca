FactoryBot.define do
  factory :ledger_entry do
    financial_account
    entry_type { :deposit_settled }
    amount_cents { 1_000 }
    currency { "RUB" }
    balance_after_cents { 1_000 }
    held_after_cents { 0 }
    description { "Balance top-up settled" }
    metadata { {} }
  end
end
