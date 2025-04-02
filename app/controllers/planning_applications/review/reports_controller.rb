# frozen_string_literal: true

module PlanningApplications
  module Review
    class ReportsController < BaseController
      skip_before_action :ensure_user_is_reviewer
      before_action :set_constraints_categories, only: %i[show]

      def show
        @constraints = @planning_application.constraints

        redirect_to planning_application_path(@planning_application) unless @planning_application.pre_application?

        @summary_of_advice = @planning_application.assessment_details.summary_of_advice.last

        @site_description = @planning_application.site_description

        respond_to do |format|
          format.html
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
