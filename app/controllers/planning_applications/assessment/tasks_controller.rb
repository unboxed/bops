# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TasksController < BaseController
      self.application_section = "Assessment"

      before_action :redirect_to_reference_url
      before_action :redirect_to_initial_task

      def index
        respond_to do |format|
          format.html
        end
      end
    end
  end
end
