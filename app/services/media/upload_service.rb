module Media
  class UploadService
    Result = Struct.new(:success?, :media_file, :error, keyword_init: true)

    def initialize(user:, file:, title:)
      @user = user
      @file = file
      @title = title
    end

    def call
      validation = ValidationService.new(file: file).call
      return failure(validation.error) unless validation.success?

      media_file = build_media_file(validation)
      media_file.file.attach(file)

      if media_file.save
        MediaProcessingJob.perform_later(media_file.id)
        success(media_file)
      else
        failure(media_file.errors.full_messages.join(", "))
      end
    end

    private

    attr_reader :user, :file, :title

    def build_media_file(validation)
      user.media_files.build(
        title: title,
        media_type: validation.media_type,
        format: validation.format,
        file_size: file.size,
        processing_status: :pending
      )
    end

    def success(media_file)
      Result.new(success?: true, media_file: media_file, error: nil)
    end

    def failure(error)
      Result.new(success?: false, media_file: nil, error: error)
    end
  end
end
