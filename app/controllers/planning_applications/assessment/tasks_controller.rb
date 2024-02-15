# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TasksController < AuthenticationController
      before_action :set_planning_application

      def index
        respond_to do |format|
          format.html
        end
      end
    end
  end
end
