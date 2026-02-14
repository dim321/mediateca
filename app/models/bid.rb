class Bid < ApplicationRecord
  # === Associations ===
  belongs_to :auction
  belongs_to :user

  # === Validations ===
  validates :amount, numericality: { greater_than: 0 }
end
