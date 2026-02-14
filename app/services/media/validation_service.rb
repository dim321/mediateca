module Media
  class ValidationService
    ALLOWED_FORMATS = %w[mp4 avi mov mp3 aac wav].freeze
    MAX_FILE_SIZE = 100.megabytes
    AUDIO_FORMATS = %w[mp3 aac wav].freeze
    VIDEO_FORMATS = %w[mp4 avi mov].freeze

    Result = Struct.new(:success?, :error, :format, :media_type, keyword_init: true)

    def initialize(file:)
      @file = file
    end

    def call
      format = extract_format
      return failure("Неподдерживаемый формат файла. Допустимые: #{ALLOWED_FORMATS.join(', ')}") unless valid_format?(format)
      return failure("Максимальный размер файла — #{MAX_FILE_SIZE / 1.megabyte} МБ") unless valid_size?

      media_type = AUDIO_FORMATS.include?(format) ? :audio : :video
      Result.new(success?: true, error: nil, format: format, media_type: media_type)
    end

    private

    attr_reader :file

    def extract_format
      File.extname(file.original_filename).delete(".").downcase
    end

    def valid_format?(format)
      ALLOWED_FORMATS.include?(format)
    end

    def valid_size?
      file.size <= MAX_FILE_SIZE
    end

    def failure(message)
      Result.new(success?: false, error: message, format: nil, media_type: nil)
    end
  end
end
