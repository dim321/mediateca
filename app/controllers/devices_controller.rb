class DevicesController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped, raise: false

  def index
    @devices = BroadcastDevice.by_city(params[:city]).order(status: :desc).order(:name)
  end

  def schedule
    @device = BroadcastDevice.find(params[:id])
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.current
    @time_slots = @device.time_slots.for_date(@date).order(start_time: :asc)
  end
end
