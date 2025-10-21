# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TasksController < BaseController
      before_action :redirect_to_reference_url

      def index
        respond_to do |format|
          format.html do
            render layout: "sidebar"
          end
        end
      end
    end
  end
end
