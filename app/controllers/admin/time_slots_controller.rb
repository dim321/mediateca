module Admin
  class TimeSlotsController < BaseController
    before_action :set_device, only: [ :index, :generate ]
    before_action :set_time_slot, only: [ :update ]

    def index
      zone = device_time_zone
      date = params[:date].presence || zone.today
      @time_slots = @device.time_slots.for_date(date, zone).order(start_time: :asc)
      @date = Date.parse(date.to_s)
    end

    def generate
      zone = device_time_zone
      date = params[:date].present? ? Date.parse(params[:date]) : zone.now.to_date

      # Check if slots already exist for this date
      existing = @device.time_slots.for_date(date, zone)
      if existing.any?
        redirect_to admin_device_time_slots_path(@device, date: date),
                    alert: t("admin.time_slots.flash.slots_already_exist", date: I18n.l(date, format: :long))
        return
      end

      # Generate 30-minute slots for the local day; DST days may not have 48.
      slots = []
      day_start = zone.local(date.year, date.month, date.day, 0, 0)
      day_end = day_start.advance(days: 1)
      start_time = day_start

      while start_time < day_end
        slots << {
          broadcast_device_id: @device.id,
          start_time: start_time.utc,
          end_time: (start_time + TimeSlot::SLOT_DURATION).utc,
          starting_price: 0,
          slot_status: :available,
          created_at: Time.current,
          updated_at: Time.current
        }
        start_time += TimeSlot::SLOT_DURATION
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

    def device_time_zone
      ActiveSupport::TimeZone[@device.time_zone] || ActiveSupport::TimeZone["UTC"]
    end

    def time_slot_params
      params.require(:time_slot).permit(:starting_price)
    end
  end
end
