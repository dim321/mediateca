class BroadcastStartJob < ApplicationJob
  queue_as :broadcasts

  def perform(broadcast_id)
    broadcast = ScheduledBroadcast.find(broadcast_id)
    return unless broadcast.scheduled?

    device = broadcast.time_slot.broadcast_device

    if device.online?
      broadcast.update!(broadcast_status: :playing, started_at: Time.current)
    else
      broadcast.update!(broadcast_status: :failed, completed_at: Time.current)
    end
  end
end
