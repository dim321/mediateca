# Permit additional fields for Devise sign_up and account_update
Rails.application.config.to_prepare do
  Devise::RegistrationsController.class_eval do
    before_action :configure_permitted_parameters

    private

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :company_name ])
      devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :company_name ])
    end
  end
end
