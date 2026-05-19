class DevicesController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped, raise: false

  def index
    @devices = BroadcastDevice.by_city(params[:city]).order(status: :desc).order(:name)
  end

  def schedule
    @device = BroadcastDevice.find(params[:id])
    zone = ActiveSupport::TimeZone[@device.time_zone] || ActiveSupport::TimeZone["UTC"]
    @date = params[:date].present? ? Date.parse(params[:date]) : zone.now.to_date
    @time_slots = @device.time_slots.for_date(@date, zone).order(start_time: :asc)
  end
end
