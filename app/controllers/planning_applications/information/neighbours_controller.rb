# frozen_string_literal: true

module PlanningApplications
  module Information
    class NeighboursController < BaseController
      def show
        @neighbours = @planning_application.consultation&.neighbours || []
      end

      private

      def current_section
        :neighbours
      end
    end
  end
end
