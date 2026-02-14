class ScheduledBroadcast < ApplicationRecord
  # === Associations ===
  belongs_to :user
  belongs_to :playlist
  belongs_to :time_slot
  belongs_to :auction, optional: true

  # === Enums ===
  enum :broadcast_status, { scheduled: 0, playing: 1, completed: 2, failed: 3 }

  # === Validations ===
  validates :broadcast_status, presence: true
  validates :time_slot_id, uniqueness: true
  validate :playlist_duration_within_slot

  # === Scopes ===
  scope :by_status, ->(status) { where(broadcast_status: status) if status.present? }

  private

  # FR-013: Playlist duration must not exceed time slot duration (30 min = 1800 sec)
  def playlist_duration_within_slot
    return unless playlist && time_slot

    slot_duration = (time_slot.end_time - time_slot.start_time).to_i
    if playlist.total_duration > slot_duration
      errors.add(:playlist, "длительность плейлиста (#{playlist.total_duration}с) превышает длительность слота (#{slot_duration}с)")
    end
  end
end
