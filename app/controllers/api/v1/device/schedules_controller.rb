module Api
  module V1
    module Device
      class SchedulesController < BaseController
        def show
          date = params[:date].present? ? Date.parse(params[:date]) : Date.current
          time_slots = current_device.time_slots
            .for_date(date)
            .includes(:scheduled_broadcast)
            .order(start_time: :asc)

          render json: {
            device: { id: current_device.id, name: current_device.name },
            time_slots: time_slots.map { |slot| serialize_slot(slot) }
          }
        end

        private

        def serialize_slot(slot)
          data = {
            id: slot.id,
            start_time: slot.start_time.iso8601,
            end_time: slot.end_time.iso8601,
            slot_status: slot.slot_status
          }

          if slot.scheduled_broadcast
            broadcast = slot.scheduled_broadcast
            data[:broadcast] = {
              id: broadcast.id,
              broadcast_status: broadcast.broadcast_status,
              playlist_id: broadcast.playlist_id
            }
          end

          data
        end
      end
    end
  end
end
