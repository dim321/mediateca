class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method

  before_action :authenticate_user!

  after_action :verify_authorized, unless: :skip_authorization?
  after_action :verify_policy_scoped, if: :verify_policy_scope?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  # Skip Pundit verify_authorized for Devise controllers and index actions
  def skip_authorization?
    devise_controller? || action_name == "index"
  end

  # Only verify policy scope on index actions in non-Devise controllers
  def verify_policy_scope?
    !devise_controller? && action_name == "index"
  end

  def user_not_authorized
    flash[:alert] = "У вас нет доступа к этому действию."
    redirect_back(fallback_location: root_path)
  end

  def record_not_found
    flash[:alert] = "Запись не найдена."
    redirect_back(fallback_location: root_path)
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "Доступ только для администраторов."
      redirect_to root_path
    end
  end
end
