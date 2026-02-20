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

      if @user.update(user_params)
        redirect_to admin_users_path, notice: "Роль пользователя «#{@user.full_name}» изменена на «#{@user.role}»."
      else
        redirect_to admin_users_path, alert: @user.errors.full_messages.join(", ")
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:role)
    end
  end
end
