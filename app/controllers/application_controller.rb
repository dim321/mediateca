class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method

  before_action :set_locale
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
    flash[:alert] = t("common.user_not_authorized")
    redirect_back(fallback_location: root_path)
  end

  def record_not_found
    flash[:alert] = t("common.record_not_found")
    redirect_back(fallback_location: root_path)
  end

  def set_locale
    I18n.locale = params[:locale].presence_in(I18n.available_locales) || session[:locale] || I18n.default_locale
    session[:locale] = I18n.locale if params[:locale].present?
  end

  def default_url_options
    I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale }
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = t("common.require_admin")
      redirect_to root_path
    end
  end
end
