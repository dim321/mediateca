class BroadcastsController < ApplicationController
  def index
    authorize ScheduledBroadcast

    scope = policy_scope(ScheduledBroadcast)
      .includes(time_slot: :broadcast_device, playlist: [])
      .order(created_at: :desc)

    scope = scope.by_status(params[:status]) if params[:status].present?

    @pagy, @broadcasts = pagy(:offset, scope, limit: 20)
  end

  def create
    authorize ScheduledBroadcast

    playlist = current_user.playlists.find(params.dig(:broadcast, :playlist_id))
    time_slot = TimeSlot.find(params.dig(:broadcast, :time_slot_id))

    result = Broadcasts::ScheduleService.new(
      user: current_user,
      playlist: playlist,
      time_slot: time_slot
    ).call

    if result.success?
      redirect_to broadcasts_path, notice: "Трансляция запланирована."
    else
      flash[:alert] = result.error
      redirect_to schedule_device_path(time_slot.broadcast_device)
    end
  end
end
