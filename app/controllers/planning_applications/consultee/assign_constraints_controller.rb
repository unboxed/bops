# frozen_string_literal: true

module PlanningApplications
  module Consultee
    class AssignConstraintsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_consultation

      def create
        respond_to do |format|
          if planning_application_constraint.update(
            consultee_ids: consultee_ids,
            consultation_required: consultation_required
          )
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
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid constraint id: #{permitted_params[:constraint].inspect}"
      end

      def consultee_ids
        Array(permitted_params[:consultee_ids]).compact_blank.map do |id|
          Integer(id)
        rescue ArgumentError
          raise ActionController::BadRequest, "Invalid consultee id: #{id.inspect}"
        end
      end

      def consultation_required
        permitted_params[:consultation_required] == ["true"]
      end

      def permitted_params
        params.require(:planning_application_constraint)
          .permit(:constraint, consultee_ids: [], consultation_required: [])
      end
    end
  end
end
