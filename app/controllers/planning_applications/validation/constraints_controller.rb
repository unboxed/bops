# frozen_string_literal: true

module PlanningApplications
  module Validation
    class ConstraintsController < BaseController
      before_action :ensure_constraint_edits_unlocked, only: %i[index update]
      before_action :set_planning_application_constraints, only: %i[update index create]
      before_action :set_other_constraints, only: %i[index]

      def index
        respond_to do |format|
          format.html
        end
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
        respond_to do |format|
          format.html do
            if @planning_application.constraints_checked!
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
        @other_constraints = Constraint.other_constraints(search_param, @planning_application)
      end

      def search_param
        params.fetch(:q, "")
      end
    end
  end
end
