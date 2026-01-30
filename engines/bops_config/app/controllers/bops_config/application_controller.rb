# frozen_string_literal: true

module BopsConfig
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController
    include BopsCore::AuditableController

    class_attribute :page_key, instance_writer: false, default: "dashboard"

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

    def application_type_param
      request.path_parameters.key?(:application_type_id) ? :application_type_id : :id
    end

    def application_type_id
      Integer(params[application_type_param])
    rescue
      raise ActionController::BadRequest, "Invalid application type id: #{params[application_type_param].inspect}"
    end
  end
end
