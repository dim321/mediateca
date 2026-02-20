module Admin
  class UsersController < BaseController
    before_action :set_user, only: :update

    def index
      @users = User.order(created_at: :desc)
    end

    def update
      if @user == current_user
        redirect_to admin_users_path, alert: "Нельзя изменить собственную роль."
        return
      end

      role = params.dig(:user, :role).to_s
      unless User.roles.key?(role)
        redirect_to admin_users_path, alert: "Недопустимая роль: «#{role}»."
        return
      end

      @user.update!(role: role)
      redirect_to admin_users_path, notice: "Роль пользователя «#{@user.full_name}» изменена на «#{role}»."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_users_path, alert: e.message
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
