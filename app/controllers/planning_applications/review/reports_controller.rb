# frozen_string_literal: true

module PlanningApplications
  module Review
    class ReportsController < BaseController
      skip_before_action :ensure_user_is_reviewer

      def show
        redirect_to planning_application_path(@planning_application) unless @planning_application.pre_application?

        @summary_of_advice = @planning_application.assessment_details.summary_of_advice.last

        respond_to do |format|
          format.html
        end
      end
    end
  end
end
