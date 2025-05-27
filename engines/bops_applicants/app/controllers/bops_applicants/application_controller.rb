# frozen_string_literal: true

module BopsApplicants
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    before_action :require_local_authority!
    helper_method :access_control_params

    private

    def set_planning_application
      if planning_application_param.present?
        @planning_application = planning_applications_scope.find_by_param!(planning_application_param)
      else
        raise BopsCore::Errors::NotFoundError, "Missing planning application reference parameter"
      end
    end

    def access_control_params
      {
        planning_application_reference: @planning_application.reference,
        change_access_id: @planning_application.change_access_id
      }
    end
  end
end
