# frozen_string_literal: true

module PlanningApplications
  module Validation
    class ConstraintsController < AuthenticationController
      before_action :set_planning_application
      before_action :ensure_constraint_edits_unlocked, only: %i[index update]
      before_action :set_planning_application_constraints, only: %i[update index create]
      before_action :set_other_constraints, only: %i[index]
      before_action :set_audits, only: %i[index]

      def index
      end

      def create
        @constraint = @planning_application_constraints.new(constraint_id: params[:constraint_id], identified_by: current_user.name)

        if @constraint.save!
          redirect_to planning_application_validation_constraints_path(@planning_application),
            notice: t(".success")
        else
          redirect_to planning_application_validation_constraints_path(@planning_application),
            alert: t(".failure")
        end
      end

      def destroy
        @constraint = @planning_application.planning_application_constraints.find(params[:id])

        if @constraint.destroy
          redirect_to planning_application_validation_constraints_path(@planning_application),
            notice: t(".success")
        else
          redirect_to planning_application_validation_constraints_path(@planning_application),
            notice: t(".failure")
        end
      end

      def update
        ActiveRecord::Base.transaction do
          @planning_application.update!(updated_address_or_boundary_geojson: true)
          @planning_application.constraints_checked!
        end

        respond_to do |format|
          format.html do
            if @planning_application.constraints_checked?
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".success")
            else
              redirect_to planning_application_validation_tasks_path(@planning_application),
                alert: t(".failure")
            end
          end
        end
      rescue ActiveRecord::ActiveRecordError => e
        redirect_to planning_application_validation_constraints_path(@planning_application),
          alert: "Couldn't update constraints with error: #{e.message}. Please contact support."
      end

      private

      def ensure_constraint_edits_unlocked
        render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
      end

      def set_planning_application_constraints
        @planning_application_constraints = @planning_application.planning_application_constraints
      end

      def set_other_constraints
        @other_constraints = Constraint.all_constraints(search_param).non_applicable_constraints(@planning_application.planning_application_constraints).sort_by(&:category)
      end

      def search_param
        params.fetch(:q, "")
      end

      def set_audits
        @audits = @planning_application.audits.where("activity_type LIKE ?", "%constraint%")
      end
    end
  end
end
