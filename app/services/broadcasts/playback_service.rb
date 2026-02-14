module Broadcasts
  class PlaybackService
    Result = Struct.new(:success?, :error, keyword_init: true)

    VALID_STATUSES = %w[playing completed failed].freeze

    def initialize(broadcast:, status:)
      @broadcast = broadcast
      @status = status.to_s
    end

    def call
      validate_status!

      case status
      when "playing"
        broadcast.update!(broadcast_status: :playing, started_at: Time.current)
      when "completed"
        broadcast.update!(broadcast_status: :completed, completed_at: Time.current)
      when "failed"
        broadcast.update!(broadcast_status: :failed, completed_at: Time.current)
      end

      Result.new(success?: true, error: nil)
    rescue StandardError => e
      Result.new(success?: false, error: e.message)
    end

    private

    attr_reader :broadcast, :status

    def validate_status!
      raise "Недопустимый статус: #{status}" unless VALID_STATUSES.include?(status)
    end
  end
end
