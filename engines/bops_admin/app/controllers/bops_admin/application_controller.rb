# frozen_string_literal: true

module BopsAdmin
  class ApplicationController < ActionController::Base
    default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

    before_action :set_local_authority
    before_action :authenticate_user!
    before_action :require_administrator!
    before_action :set_back_path

    helper_method :current_local_authority

    layout "application"

    private

    def set_local_authority
      @local_authority = LocalAuthority.find_by!(subdomain: request.subdomain)
    end

    def current_local_authority
      @local_authority
    end

    def require_administrator!
      unless current_user.administrator?
        redirect_to main_app.root_url, alert: t("bops_admin.administrator_required", path: request.path)
      end
    end

    def set_back_path
      session[:back_path] = request.referer if request.get?
      @back_path = session[:back_path]
    end
  end
end
