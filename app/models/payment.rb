class Payment < ApplicationRecord
  # === Enums ===
  enum :provider, { stripe: 0, yookassa: 1 }
  enum :operation_type, { top_up: 0, refund: 1 }
  enum :status, {
    pending: 0,
    requires_action: 1,
    processing: 2,
    succeeded: 3,
    failed: 4,
    canceled: 5
  }

  # === Associations ===
  belongs_to :user
  belongs_to :financial_account
  has_many :ledger_entries, dependent: :restrict_with_error

  # === Validations ===
  validates :currency, presence: true
  validates :idempotency_key, presence: true, uniqueness: true
  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
end
