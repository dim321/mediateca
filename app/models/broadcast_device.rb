class BroadcastDevice < ApplicationRecord
  # === Associations ===
  has_many :time_slots, dependent: :destroy
  has_many :device_group_memberships, dependent: :destroy
  has_many :device_groups, through: :device_group_memberships

  # === Enums ===
  enum :status, { offline: 0, online: 1 }

  # === Validations ===
  validates :name, presence: true
  validates :city, presence: true
  validates :address, presence: true
  validates :time_zone, presence: true
  validates :api_token, presence: true, uniqueness: true
  validate :valid_time_zone

  # === Callbacks ===
  before_validation :generate_api_token, on: :create

  # === Scopes ===
  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :by_status, ->(status) { where(status: status) if status.present? }

  private

  def generate_api_token
    self.api_token ||= SecureRandom.hex(32)
  end

  def valid_time_zone
    return if time_zone.blank?

    unless ActiveSupport::TimeZone[time_zone]
      errors.add(:time_zone, "недопустимый часовой пояс")
    end
  end
end
