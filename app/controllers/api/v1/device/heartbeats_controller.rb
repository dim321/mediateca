module Api
  module V1
    module Device
      class HeartbeatsController < BaseController
        def create
          current_device.update!(
            status: :online,
            last_heartbeat_at: Time.current
          )

          render json: { status: "ok", device_id: current_device.id }
        end
      end
    end
  end
end
