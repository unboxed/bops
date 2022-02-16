# frozen_string_literal: true

class PlanningApplication
  class ValidationTasksController < AuthenticationController
    before_action :set_planning_application

    def index; end

    private

    def set_planning_application
      @planning_application = current_local_authority.planning_applications.find(planning_application_id)
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end
  end
end
