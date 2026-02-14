class User < ApplicationRecord
  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # === Enums ===
  enum :role, { user: 0, admin: 1 }

  # === Associations ===
  has_many :media_files, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :bids, dependent: :restrict_with_error
  has_many :transactions, dependent: :restrict_with_error
  has_many :scheduled_broadcasts, dependent: :restrict_with_error

  # === Validations ===
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  # === Instance methods ===
  def full_name
    "#{first_name} #{last_name}"
  end

  def sufficient_balance?(amount)
    balance >= amount
  end
end
