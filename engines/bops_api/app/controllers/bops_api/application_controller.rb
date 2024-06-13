# frozen_string_literal: true

module BopsApi
  class ApplicationController < ActionController::Base
    include ErrorHandler
    include SchemaValidation

    protect_from_forgery with: :null_session, prepend: true
    wrap_parameters false

    before_action :set_local_authority

    private

    def set_local_authority
      @local_authority = LocalAuthority.find_by!(subdomain: request.subdomain)
    end

    def find_planning_application param
      if /\A\d{2}-\d{5}-[A-Za-z0-9]+\z/.match?(param)
        planning_applications_scope.find_by!(reference: param)
      else
        planning_applications_scope.find(Integer(param))
      end
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid planning application reference or id: #{param.inspect}"
    end
  end
end
