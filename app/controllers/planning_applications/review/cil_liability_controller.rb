# frozen_string_literal: true

module PlanningApplications
  module Review
    class CilLiabilityController < BaseController
      before_action :redirect_to_review_tasks, unless: :cil_feature?

      def update
        @previous_decision = @planning_application.cil_liable
        if @planning_application.update(cil_liability_params)
          record_audit_for_cil_liability!
          redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-cil-liability"), notice: t(".success")
        else
          render :edit
        end
      end

      private

      def cil_liability_params
        params.permit(planning_application: [:cil_liable]).fetch(:planning_application, {})
      end

      def record_audit_for_cil_liability!
        Audit.create!(
          planning_application_id: @planning_application.id,
          user: Current.user,
          activity_type: "review_cil_liability",
          audit_comment:,
          activity_information:
        )
      end

      def audit_comment
        if @previous_decision.nil?
          "The validation officer had not confirmed whether the application was liable"
        else
          "Previously marked as#{" not" unless @previous_decision} liable by validation officer"
        end
      end

      def activity_information
        if @planning_application.cil_liable.nil?
          "Reviewer marked application as not needing confirmation for CIL liability"
        else
          "Reviewer marked application as#{" not" unless @planning_application.cil_liable} liable for CIL"
        end
      end

      def cil_feature?
        @planning_application.application_type.cil?
      end
    end
  end
end
