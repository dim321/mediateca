class TimeSlot < ApplicationRecord
  SLOT_DURATION = 30.minutes

  # === Associations ===
  belongs_to :broadcast_device
  has_one :auction, dependent: :destroy
  has_one :scheduled_broadcast, dependent: :nullify

  # === Enums ===
  enum :slot_status, { available: 0, auction_active: 1, sold: 2 }

  # === Validations ===
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :starting_price, numericality: { greater_than_or_equal_to: 0 }
  validates :start_time, uniqueness: { scope: :broadcast_device_id }
  validate :end_time_after_start_time
  validate :thirty_minute_duration

  # === Scopes ===
  scope :for_date, ->(date) {
    date = Date.parse(date.to_s)
    where(start_time: date.beginning_of_day..date.end_of_day)
  }

  def display_time_in_zone
    zone = ActiveSupport::TimeZone[broadcast_device.time_zone]
    return start_time unless zone

    "#{start_time.in_time_zone(zone).strftime('%H:%M')} — #{end_time.in_time_zone(zone).strftime('%H:%M')}"
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    errors.add(:end_time, "должно быть позже start_time") if end_time <= start_time
  end

  def thirty_minute_duration
    return if start_time.blank? || end_time.blank?

    unless (end_time - start_time) == SLOT_DURATION
      errors.add(:base, "Длительность слота должна быть 30 минут")
    end
  end
end
