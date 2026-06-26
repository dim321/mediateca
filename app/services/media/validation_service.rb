module Media
  class ValidationService
    ALLOWED_FORMATS = %w[mp4 avi mov mp3 aac wav].freeze
    MAX_FILE_SIZE = 100.megabytes
    AUDIO_FORMATS = %w[mp3 aac wav].freeze
    VIDEO_FORMATS = %w[mp4 avi mov].freeze

    Result = Struct.new(:success?, :error, :format, :media_type, :file_size, keyword_init: true)
    FileMetadata = Struct.new(:filename, :size, keyword_init: true)

    def initialize(file:)
      @file = file
    end

    def call
      metadata = file_metadata
      return failure("Файл не выбран") unless metadata

      format = extract_format
      return failure("Неподдерживаемый формат файла. Допустимые: #{ALLOWED_FORMATS.join(', ')}") unless valid_format?(format)
      return failure("Максимальный размер файла — #{MAX_FILE_SIZE / 1.megabyte} МБ") unless valid_size?

      media_type = AUDIO_FORMATS.include?(format) ? :audio : :video
      Result.new(success?: true, error: nil, format: format, media_type: media_type, file_size: metadata.size)
    end

    private

    attr_reader :file

    def file_metadata
      @file_metadata ||= file.is_a?(String) ? blob_metadata : uploaded_file_metadata
    end

    def uploaded_file_metadata
      return unless file.respond_to?(:original_filename) && file.respond_to?(:size)

      FileMetadata.new(filename: file.original_filename, size: file.size)
    end

    def blob_metadata
      blob = ActiveStorage::Blob.find_signed(file)
      return unless blob

      FileMetadata.new(filename: blob.filename.to_s, size: blob.byte_size)
    end

    def extract_format
      File.extname(file_metadata.filename).delete(".").downcase
    end

    def valid_format?(format)
      ALLOWED_FORMATS.include?(format)
    end

    def valid_size?
      file_metadata.size <= MAX_FILE_SIZE
    end

    def failure(message)
      Result.new(success?: false, error: message, format: nil, media_type: nil, file_size: nil)
    end
  end
end
