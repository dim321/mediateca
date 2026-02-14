class Playlist < ApplicationRecord
  # === Associations ===
  belongs_to :user
  has_many :playlist_items, -> { order(position: :asc) }, dependent: :destroy, inverse_of: :playlist
  has_many :media_files, through: :playlist_items
  has_many :scheduled_broadcasts, dependent: :restrict_with_error

  # === Validations ===
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :total_duration, numericality: { greater_than_or_equal_to: 0 }

  # === Callbacks ===
  # Recalculate total_duration when items change (via touch from PlaylistItem)
  after_touch :recalculate_total_duration!

  def recalculate_total_duration!
    update_column(:total_duration, playlist_items.joins(:media_file).sum("media_files.duration"))
  end

  def formatted_duration
    minutes = total_duration / 60
    seconds = total_duration % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end
end
