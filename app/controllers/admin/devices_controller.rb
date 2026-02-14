module Admin
  class DevicesController < BaseController
    before_action :set_device, only: [ :show, :edit, :update, :destroy ]

    def index
      @pagy, @devices = pagy(
        :offset,
        BroadcastDevice.by_city(params[:city]).by_status(params[:status]).order(created_at: :desc),
        limit: 20
      )
    end

    def show
      @time_slots = @device.time_slots.order(start_time: :asc)
    end

    def new
      @device = BroadcastDevice.new
    end

    def create
      @device = BroadcastDevice.new(device_params)

      if @device.save
        redirect_to admin_device_path(@device), notice: "Устройство создано. API токен: #{@device.api_token}"
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @device.update(device_params)
        redirect_to admin_device_path(@device), notice: "Устройство обновлено."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @device.destroy!
      redirect_to admin_devices_path, notice: "Устройство удалено."
    end

    private

    def set_device
      @device = BroadcastDevice.find(params[:id])
    end

    def device_params
      params.require(:broadcast_device).permit(:name, :city, :address, :time_zone, :description)
    end
  end
end
