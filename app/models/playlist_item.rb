class PlaylistItem < ApplicationRecord
  # === Associations ===
  belongs_to :playlist, touch: true, counter_cache: :items_count
  belongs_to :media_file

  # === Validations ===
  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :position, uniqueness: { scope: :playlist_id }
  validates :media_file_id, uniqueness: { scope: :playlist_id }
  validate :media_file_belongs_to_playlist_user

  # === Callbacks ===
  after_create :recalculate_playlist_duration
  after_destroy :recalculate_playlist_duration

  private

  def media_file_belongs_to_playlist_user
    return unless playlist && media_file
    return if media_file.user_id == playlist.user_id

    errors.add(:media_file, :invalid)
  end

  def recalculate_playlist_duration
    playlist.recalculate_total_duration!
  end
end
