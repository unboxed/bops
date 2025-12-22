# frozen_string_literal: true

module BopsPreapps
  class AssignConstraintsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_task

    def create
      if planning_application_constraint.update(assignment_params)
        redirect_to route_for(:task, @planning_application, @task)
      else
        redirect_to route_for(:task, @planning_application, @task),
          alert: t(".failure")
      end
    end

    private

    def planning_application_constraint
      @planning_application.planning_application_constraints.find(constraint_id)
    end

    def constraint_id
      Integer(permitted_params[:constraint])
    rescue ArgumentError
      raise ActionController::BadRequest, "Invalid constraint id: #{permitted_params[:constraint].inspect}"
    end

    def consultation_required
      permitted_params[:consultation_required] == ["true"]
    end

    def permitted_params
      params.require(:planning_application_constraint).permit(:constraint, consultation_required: [])
    end

    def assignment_params
      {consultation_required: consultation_required}
    end
  end
end
