# frozen_string_literal: true

module PlanningApplications
  module Consultee
    class ConstraintConsulteesController < AuthenticationController
      before_action :set_planning_application
      before_action :set_consultation

      def destroy
        constraint_consultee.destroy!

        redirect_to planning_application_consultees_url(@planning_application), notice: t("consultee_constraint_consultees.destroy.success")
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
end
