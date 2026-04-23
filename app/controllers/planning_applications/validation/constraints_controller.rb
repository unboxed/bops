# frozen_string_literal: true

module PlanningApplications
  module Validation
    class ConstraintsController < BaseController
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
          redirect_to planning_application_validation_constraints_path(@planning_application, return_to: params[:return_to]),
            notice: t(".success")
        else
          redirect_to planning_application_validation_constraints_path(@planning_application, return_to: params[:return_to]),
            alert: t(".failure")
        end
      end

      def destroy
        @constraint = @planning_application.planning_application_constraints.find(params[:id])

        if @constraint.destroy
          redirect_to planning_application_validation_constraints_path(@planning_application, return_to: params[:return_to]),
            notice: t(".success")
        else
          redirect_to planning_application_validation_constraints_path(@planning_application, return_to: params[:return_to]),
            notice: t(".failure")
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @planning_application.constraints_checked!
              redirect_to redirect_path, notice: t(".success")
            else
              redirect_to planning_application_validation_path(@planning_application),
                alert: t(".failure")
            end
          end
        end
      rescue ActiveRecord::ActiveRecordError => e
        redirect_to planning_application_validation_constraints_path(@planning_application),
          alert: "Couldn't update constraints with error: #{e.message}. Please contact support."
      end

      private

      def set_planning_application_constraints
        @planning_application_constraints = @planning_application.planning_application_constraints
      end

      def set_other_constraints
        @other_constraints = Constraint.other_constraints(search_param, @planning_application)
      end

      def search_param
        params.fetch(:q, "")
      end

      def redirect_path
        params[:return_to].presence || planning_application_validation_path(@planning_application)
      end
    end
  end
end
