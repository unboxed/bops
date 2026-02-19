# frozen_string_literal: true

module PlanningApplications
  module Review
    class TasksController < BaseController
      def index
        @show_header_bar = false

        if session[:errors].present?
          session[:errors].each do |attr, err|
            @planning_application.errors.add(attr, err)
          end
          session[:errors] = nil
        end

        respond_to do |format|
          format.html
        end
      end
    end
  end
end
