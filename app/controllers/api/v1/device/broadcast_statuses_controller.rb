module Api
  module V1
    module Device
      class BroadcastStatusesController < BaseController
        def create
          broadcast = ScheduledBroadcast
            .joins(:time_slot)
            .find_by!(
              id: params[:broadcast_id],
              time_slots: { broadcast_device_id: current_device.id }
            )

          result = Broadcasts::PlaybackService.new(
            broadcast: broadcast,
            status: params[:status]
          ).call

          if result.success?
            render json: { status: "ok", broadcast_status: broadcast.reload.broadcast_status }
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
