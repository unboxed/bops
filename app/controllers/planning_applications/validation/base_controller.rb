# frozen_string_literal: true

module PlanningApplications
  module Validation
    class BaseController < AuthenticationController
      before_action :set_planning_application
      before_action :redirect_to_reference_url
      before_action :show_sidebar

      private

      def show_sidebar
        @show_sidebar = @planning_application.case_record.tasks.find_by(section: "Validation")
      end
    end
  end
end
