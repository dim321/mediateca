module Admin
  class UsersController < BaseController
    before_action :set_user, only: :update

    def index
      @users = User.order(created_at: :desc)
    end

    def update
      if @user == current_user
        redirect_to admin_users_path, alert: t("admin.users.flash.cannot_change_own_role")
        return
      end

      role = params.dig(:user, :role).to_s
      unless User.roles.key?(role)
        redirect_to admin_users_path, alert: t("admin.users.flash.invalid_role", role: role)
        return
      end

      @user.update!(role: role)
      role_label = t("admin.users.roles.#{role}")
      redirect_to admin_users_path, notice: t("admin.users.flash.role_updated", name: @user.full_name, role: role_label)
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_users_path, alert: e.message
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
