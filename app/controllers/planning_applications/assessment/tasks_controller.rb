# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class TasksController < BaseController
      def index
        respond_to do |format|
          format.html
        end
      end
    end
  end
end
