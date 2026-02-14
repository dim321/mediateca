class MediaProcessingJob < ApplicationJob
  queue_as :media_processing

  def perform(media_file_id)
    media_file = MediaFile.find_by(id: media_file_id)
    return unless media_file

    media_file.processing!

    begin
      media_file.file.open do |tempfile|
        movie = FFMPEG::Movie.new(tempfile.path)
        if movie.valid?
          media_file.update!(
            duration: movie.duration.to_i,
            processing_status: :ready
          )
        else
          media_file.failed!
        end
      end
    rescue FFMPEG::Error, StandardError => e
      Rails.logger.error("MediaProcessingJob failed for #{media_file_id}: #{e.message}")
      media_file.failed!
    end
  end
end
