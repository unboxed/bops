# frozen_string_literal: true

module PlanningApplications
  module Validation
    class TasksController < BaseController
      before_action :set_items_counter, only: :index

      def index
        @show_sidebar = if @planning_application.pre_application? && Rails.configuration.use_new_sidebar_layout && !BLOCKED_SIDEBAR_EMAILS.include?(current_user&.email)
          @planning_application.case_record.tasks.find_by(section: "Validation")
        end

        respond_to do |format|
          format.html
        end
      end

      private

      def planning_applications_scope
        super
      end

      def set_items_counter
        @items_counter = @planning_application.items_counter
      end
    end
  end
end
