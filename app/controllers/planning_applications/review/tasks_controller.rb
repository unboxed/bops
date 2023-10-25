# frozen_string_literal: true

module PlanningApplications
  module Review
    class TasksController < AuthenticationController
      before_action :set_planning_application
      before_action :ensure_user_is_reviewer
      before_action :set_condition_set
      before_action :set_condition_set_review

      def index
        respond_to do |format|
          format.html
        end
      end

      private

      def set_condition_set
        @condition_set = @planning_application.condition_set || @planning_application.create_condition_set!
      end

      def set_condition_set_review
        @condition_set_review = @condition_set.review || @condition_set.create_review!
      end
    end
  end
end
