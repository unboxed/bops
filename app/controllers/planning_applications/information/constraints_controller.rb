# frozen_string_literal: true

module PlanningApplications
  module Information
    class ConstraintsController < BaseController
      def show
        @planning_application_constraints = @planning_application.planning_application_constraints
      end
    end
  end
end
