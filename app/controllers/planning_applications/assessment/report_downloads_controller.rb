# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ReportDownloadsController < AuthenticationController
      before_action :set_planning_application

      def show
        @blank_layout = true
      end
    end
  end
end