class User < ApplicationRecord
  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # === Enums ===
  enum :role, { user: 0, admin: 1 }

  # === Associations ===
  has_one :financial_account, dependent: :restrict_with_error
  has_many :media_files, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :bids, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error
  has_many :scheduled_broadcasts, dependent: :restrict_with_error

  # === Validations ===
  validates :first_name, presence: true
  validates :last_name, presence: true

  # === Instance methods ===
  def full_name
    "#{first_name} #{last_name}"
  end

  def financial_account!
    financial_account || create_financial_account!(currency: "RUB")
  rescue ActiveRecord::RecordNotUnique
    reload.financial_account || FinancialAccount.find_by!(user_id: id)
  end
end
