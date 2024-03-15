# frozen_string_literal: true

module BopsConfig
  class ApplicationController < ActionController::Base
    default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

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

    def application_type_id
      param_value = params[request.path_parameters.key?(:application_type_id) ? :application_type_id : :id]
      Integer(param_value)
    rescue
      raise ActionController::BadRequest, "Invalid application type id: #{param_value}"
    end
  end
end
