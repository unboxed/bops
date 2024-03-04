# frozen_string_literal: true

module PlanningApplications
  module Consultee
    class AssignConstraintsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_consultation

      def create
        respond_to do |format|
          if planning_application_constraint.update(consultee_id: consultee_id)
            format.html do
              redirect_to planning_application_consultees_url(@planning_application)
            end
          else
            format.html { render :index }
          end
        end
      end

      private

      def planning_application_constraint
        PlanningApplicationConstraint.find(constraint_id)
      end

      def constraint_id
        Integer(permitted_params[:constraint])
      end

      def consultee_id
        Integer(permitted_params[:consultee])
      end

      def permitted_params
        params.require(:constraint).permit([:constraint, :consultee])
      end
    end
  end
end
