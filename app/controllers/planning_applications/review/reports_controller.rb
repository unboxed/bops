# frozen_string_literal: true

module PlanningApplications
  module Review
    class ReportsController < BaseController
      before_action :set_constraints_categories, only: %i[show]

      def show
        @constraints = @planning_application.constraints

        redirect_to planning_application_path(@planning_application) unless @planning_application.pre_application?

        summary_tags = @planning_application.assessment_details.map(&:summary_tag)
        @outcome_status = if summary_tags.any?(:does_not_comply)
          :does_not_comply
        elsif summary_tags.present? && summary_tags.all?(:complies)
          :complies
        else
          :needs_changes
        end
      end

      private

      def set_constraints_categories
        @all_constraints = Constraint.where(local_authority: @local_authority)
        @constraints_categories = @all_constraints.distinct.pluck(:category)
      end
    end
  end
end
