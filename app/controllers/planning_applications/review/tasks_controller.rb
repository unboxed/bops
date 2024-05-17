# frozen_string_literal: true

module PlanningApplications
  module Review
    class TasksController < BaseController
      def index
        respond_to do |format|
          format.html
        end
      end
    end
  end
end
