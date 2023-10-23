# frozen_string_literal: true

module PlanningApplications
  module Review
    class TasksController < AuthenticationController
      before_action :set_planning_application
      before_action :ensure_user_is_reviewer

      def index
        respond_to do |format|
          format.html
        end
      end
    end
  end
end
