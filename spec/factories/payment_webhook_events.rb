FactoryBot.define do
  factory :payment_webhook_event do
    provider { :stripe }
    event_id { SecureRandom.uuid }
    event_type { "payment_intent.succeeded" }
    payload { { "id" => event_id } }
  end
end
