class LedgerEntry < ApplicationRecord
  # === Enums ===
  enum :entry_type, {
    deposit_settled: 0,
    hold: 1,
    release: 2,
    capture: 3,
    refund: 4,
    adjustment: 5
  }

  # === Associations ===
  belongs_to :financial_account
  belongs_to :payment, optional: true
  belongs_to :reference, polymorphic: true, optional: true

  # === Validations ===
  validates :currency, presence: true
  validates :description, presence: true
  validates :amount_cents, numericality: { only_integer: true, other_than: 0 }
  validates :balance_after_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :held_after_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # === Immutability ===
  before_destroy :prevent_destroy

  def readonly?
    persisted?
  end

  private

  def prevent_destroy
    raise ActiveRecord::ReadOnlyRecord, "#{self.class.name} is immutable"
  end
end
