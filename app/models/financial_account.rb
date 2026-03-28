class FinancialAccount < ApplicationRecord
  # === Enums ===
  enum :status, { active: 0, suspended: 1, closed: 2 }

  # === Associations ===
  belongs_to :user
  has_many :ledger_entries, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error

  # === Validations ===
  validates :user, uniqueness: true
  validates :currency, presence: true
  validates :available_amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :held_amount_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # === Instance methods ===
  def available_amount = cents_to_amount(available_amount_cents)
  def held_amount = cents_to_amount(held_amount_cents)
  def total_amount = cents_to_amount(available_amount_cents.to_i + held_amount_cents.to_i)

  private

  def cents_to_amount(cents)
    return BigDecimal("0") if cents.nil?

    BigDecimal(cents, 0) / 100
  end
end
