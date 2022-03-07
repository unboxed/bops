# frozen_string_literal: true

class PlanningApplication
  class ValidationTasksController < AuthenticationController
    before_action :set_planning_application

    def index; end

    private

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def planning_applications_scope
      current_local_authority.planning_applications.includes(:other_change_validation_requests)
    end

    def planning_application_id
      Integer(params[:planning_application_id])
    end
  end
end
