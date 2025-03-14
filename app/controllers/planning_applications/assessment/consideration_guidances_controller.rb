# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConsiderationGuidancesController < BaseController
      def index
        @consultee_responses = @planning_application.consultation.consultee_responses

        respond_to do |format|
          format.html
        end
      end
    end
  end
end
