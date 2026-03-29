class PaymentWebhookEvent < ApplicationRecord
  # === Enums ===
  enum :provider, { stripe: 0, yookassa: 1 }

  # === Validations ===
  validates :provider, presence: true
  validates :event_id, presence: true
  validates :event_type, presence: true
  validates :payload, presence: true

  # === Scopes ===
  scope :unprocessed, -> { where(processed_at: nil) }
end
