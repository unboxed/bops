# frozen_string_literal: true

module BopsConfig
  class ApplicationController < ActionController::Base
    include BopsCore::AuditableController

    self.audit_payload = -> {
      {
        engine: "bops_config",
        params: request.path_parameters,
        user: current_user.audit_attributes
      }
    }

    before_action :authenticate_user!
    before_action :require_global_administrator!
    before_action :set_back_path

    layout "application"

    private

    def require_global_administrator!
      unless current_user&.global_administrator?
        redirect_to root_url
      end
    end

    def set_back_path
      session[:back_path] = request.referer if request.get?
      @back_path = session[:back_path]
    end

    def application_type_param
      request.path_parameters.key?(:application_type_id) ? :application_type_id : :id
    end

    def application_type_id
      Integer(params[application_type_param])
    rescue
      raise ActionController::BadRequest, "Invalid application type id: #{params[application_type_param].inspect}"
    end

    def current_local_authority
      nil
    end
    helper_method :current_local_authority
  end
end
