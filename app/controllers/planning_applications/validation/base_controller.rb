# frozen_string_literal: true

module PlanningApplications
  module Validation
    class BaseController < AuthenticationController
      before_action :set_planning_application

      def index
        redirect_to planning_application_validation_tasks_url(@planning_application)
      end
    end
  end
end