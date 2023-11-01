# frozen_string_literal: true

module PlanningApplications
  class AssessmentTasksController < AuthenticationController
    before_action :set_planning_application
    before_action :set_condition_set

    def index
      respond_to do |format|
        format.html
      end
    end

    private

    def set_condition_set
      @condition_set = @planning_application.condition_set || @planning_application.create_condition_set!
    end
  end
end
