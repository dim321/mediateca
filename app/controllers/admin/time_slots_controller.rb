module Admin
  class TimeSlotsController < BaseController
    before_action :set_device, only: [ :index, :generate ]
    before_action :set_time_slot, only: [ :update ]

    def index
      date = params[:date] || Date.current
      @time_slots = @device.time_slots.for_date(date).order(start_time: :asc)
      @date = Date.parse(date.to_s)
    end

    def generate
      zone = ActiveSupport::TimeZone[@device.time_zone] || ActiveSupport::TimeZone["UTC"]
      date = params[:date].present? ? Date.parse(params[:date]) : zone.now.to_date

      # Check if slots already exist for this date
      existing = @device.time_slots.for_date(date)
      if existing.any?
        redirect_to admin_device_time_slots_path(@device, date: date),
                    alert: t("admin.time_slots.flash.slots_already_exist", date: I18n.l(date, format: :long))
        return
      end

      # Generate 48 x 30-minute slots for the day (in device timezone, stored as UTC)
      slots = []
      day_start = zone.local(date.year, date.month, date.day, 0, 0)
      48.times do |i|
        start_time = day_start + (i * 30).minutes
        slots << {
          broadcast_device_id: @device.id,
          start_time: start_time.utc,
          end_time: (start_time + 30.minutes).utc,
          starting_price: 0,
          slot_status: :available,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      TimeSlot.insert_all(slots)

      redirect_to admin_device_time_slots_path(@device, date: date),
                  notice: t("admin.time_slots.flash.generated", date: I18n.l(date, format: :long))
    end

    def update
      if @time_slot.update(time_slot_params)
        redirect_back fallback_location: admin_device_path(@time_slot.broadcast_device),
                      notice: t("admin.time_slots.flash.price_updated")
      else
        redirect_back fallback_location: admin_device_path(@time_slot.broadcast_device),
                      alert: @time_slot.errors.full_messages.join(", ")
      end
    end

    private

    def set_device
      @device = BroadcastDevice.find(params[:device_id])
    end

    def set_time_slot
      @time_slot = TimeSlot.find(params[:id])
    end

    def time_slot_params
      params.require(:time_slot).permit(:starting_price)
    end
  end
end
