# frozen_string_literal: true

module BopsApplicants
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    before_action :require_local_authority!

    private

    def set_planning_application
      @planning_application = planning_applications_scope.find_by_param!(planning_application_param)
    end
  end
end
