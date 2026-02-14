class Auction < ApplicationRecord
  # === Associations ===
  belongs_to :time_slot
  belongs_to :highest_bidder, class_name: "User", optional: true
  has_many :bids, dependent: :restrict_with_error

  # === Enums ===
  enum :auction_status, { open: 0, closed: 1, cancelled: 2 }

  # === Validations ===
  validates :starting_price, numericality: { greater_than: 0 }
  validates :closes_at, presence: true
  validates :time_slot_id, uniqueness: true

  # === Scopes ===
  scope :closing_soon, ->(within = 10.seconds) {
    open.where(closes_at: ..Time.current + within)
  }
end
