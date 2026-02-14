module Api
  module V1
    module Device
      class BaseController < ActionController::API
        before_action :authenticate_device!

        private

        def authenticate_device!
          token = request.headers["Authorization"]&.gsub(/^Bearer\s/, "")
          @current_device = BroadcastDevice.find_by(api_token: token) if token.present?

          render json: { error: "Unauthorized" }, status: :unauthorized unless @current_device
        end

        attr_reader :current_device
      end
    end
  end
end
