class Transaction < ApplicationRecord
  # === Associations ===
  belongs_to :user
  belongs_to :reference, polymorphic: true, optional: true

  # === Enums ===
  enum :transaction_type, { deposit: 0, deduction: 1 }

  # === Validations ===
  validates :transaction_type, presence: true
  validates :description, presence: true
  validate :amount_not_zero

  # === Immutability ===
  # Transactions are append-only; cannot be updated or deleted
  def readonly?
    persisted?
  end

  private

  def amount_not_zero
    errors.add(:amount, "не может быть равна нулю") if amount&.zero?
  end
end
