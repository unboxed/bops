# frozen_string_literal: true

module BopsPreapps
  class ConstraintConsulteesController < AuthenticationController
    before_action :set_planning_application
    before_action :set_task

    def destroy
      constraint_consultee.destroy!

      redirect_to route_for(:task, @planning_application, @task),
        notice: t(".success")
    end

    private

    def constraint_consultee
      @constraint_consultee ||= ::PlanningApplicationConstraintConsultee
        .joins(:planning_application_constraint)
        .where(planning_application_constraints: {planning_application_id: @planning_application.id})
        .find(params[:id])
    end
  end
end
