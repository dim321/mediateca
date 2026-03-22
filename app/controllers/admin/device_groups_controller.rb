module Admin
  class DeviceGroupsController < BaseController
    before_action :set_group, only: [ :show, :edit, :update, :destroy, :add_devices, :remove_device ]

    def index
      @groups = DeviceGroup.order(:name)
    end

    def show
      @devices = @group.broadcast_devices.order(:name)
      @available_devices = BroadcastDevice.where.not(id: @group.broadcast_device_ids).order(:name)
    end

    def new
      @group = DeviceGroup.new
    end

    def create
      @group = DeviceGroup.new(group_params)

      if @group.save
        redirect_to admin_device_group_path(@group), notice: t("admin.device_groups.flash.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @group.update(group_params)
        redirect_to admin_device_group_path(@group), notice: t("admin.device_groups.flash.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @group.destroy!
      redirect_to admin_device_groups_path, notice: t("admin.device_groups.flash.destroyed")
    end

    def add_devices
      device_ids = Array(params[:device_ids])
      device_ids.each do |device_id|
        @group.device_group_memberships.find_or_create_by(broadcast_device_id: device_id)
      end
      redirect_to admin_device_group_path(@group), notice: t("admin.device_groups.flash.devices_added")
    end

    def remove_device
      membership = @group.device_group_memberships.find_by(broadcast_device_id: params[:device_id])
      membership&.destroy
      redirect_to admin_device_group_path(@group), notice: t("admin.device_groups.flash.device_removed")
    end

    private

    def set_group
      @group = DeviceGroup.find(params[:id])
    end

    def group_params
      params.require(:device_group).permit(:name, :description)
    end
  end
end
