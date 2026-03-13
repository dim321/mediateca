class MediaFile < ApplicationRecord
  include Turbo::Broadcastable

  # === Associations ===
  belongs_to :user
  has_one_attached :file
  has_many :playlist_items, dependent: :restrict_with_error
  has_many :playlists, through: :playlist_items

  # === Enums ===
  enum :media_type, { audio: 0, video: 1 }
  enum :processing_status, { pending: 0, processing: 1, ready: 2, failed: 3 }

  # === Validations ===
  validates :title, presence: true
  validates :media_type, presence: true
  validates :format, presence: true, inclusion: { in: %w[mp4 avi mov mp3 aac wav] }
  validates :file_size, numericality: { less_than_or_equal_to: 100.megabytes }

  # === Scopes ===
  scope :by_media_type, ->(type) { where(media_type: type) if type.present? }
  scope :recent, -> { order(created_at: :desc) }

  # Determine media type from file format
  def audio_format?
    %w[mp3 aac wav].include?(format)
  end

  def video_format?
    %w[mp4 avi mov].include?(format)
  end

  def formatted_duration
    return "—" unless duration
    minutes = duration / 60
    seconds = duration % 60
    "#{minutes}:#{seconds.to_s.rjust(2, '0')}"
  end

  def formatted_file_size
    ActiveSupport::NumberHelper.number_to_human_size(file_size)
  end

  # Транслирует обновление статуса для Turbo Stream
  def broadcast_status_update
    broadcast_replace_to(
      "media_file_#{id}_status",
      target: "media_file_#{id}_status",
      partial: "media_files/processing_status",
      locals: { media_file: self }
    )
  end
end
