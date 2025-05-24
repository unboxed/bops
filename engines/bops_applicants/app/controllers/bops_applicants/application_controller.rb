# frozen_string_literal: true

module BopsApplicants
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    before_action :require_local_authority!

    private

    def set_planning_application
      if planning_application_param.present?
        @planning_application = planning_applications_scope.find_by_param!(planning_application_param)
      else
        raise BopsCore::Errors::NotFoundError, "Missing planning application reference parameter"
      end
    end
  end
end
