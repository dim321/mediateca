module Admin
  class BaseController < ApplicationController
    before_action :require_admin

    # Admin controllers use require_admin for access control instead of Pundit
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped, raise: false

    layout "admin"
  end
end
