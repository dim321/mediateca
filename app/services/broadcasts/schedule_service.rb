module Broadcasts
  class ScheduleService
    Result = Struct.new(:success?, :broadcast, :error, keyword_init: true)

    def initialize(user:, playlist:, time_slot:, auction: nil)
      @user = user
      @playlist = playlist
      @time_slot = time_slot
      @auction = auction
    end

    def call
      validate_slot_available!
      validate_playlist_duration!

      broadcast = create_broadcast
      update_time_slot_status

      Result.new(success?: true, broadcast: broadcast, error: nil)
    rescue ServiceError => e
      Result.new(success?: false, broadcast: nil, error: e.message)
    end

    private

    attr_reader :user, :playlist, :time_slot, :auction

    def validate_slot_available!
      unless time_slot.available?
        raise ServiceError, "Слот недоступен для бронирования"
      end
    end

    def validate_playlist_duration!
      slot_duration = (time_slot.end_time - time_slot.start_time).to_i
      if playlist.total_duration > slot_duration
        raise ServiceError, "Превышена длительность: плейлист (#{playlist.total_duration}с) > слот (#{slot_duration}с)"
      end
    end

    def create_broadcast
      attrs = {
        user: user,
        playlist: playlist,
        time_slot: time_slot,
        broadcast_status: :scheduled
      }
      attrs[:auction_id] = auction.id if auction

      ScheduledBroadcast.create!(attrs)
    end

    def update_time_slot_status
      time_slot.update!(slot_status: :sold)
    end

    class ServiceError < StandardError; end
  end
end
