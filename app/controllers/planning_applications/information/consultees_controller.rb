# frozen_string_literal: true

module PlanningApplications
  module Information
    class ConsulteesController < BaseController
      def show
        @consultees = @planning_application.consultation&.consultees || []
      end
    end
  end
end
