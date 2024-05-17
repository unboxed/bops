# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module Terms
      class PositionsController < BaseController
        include BopsCore::PositionsController

        private

        def set_collection
          @collection = @planning_application.heads_of_term
        end

        def set_record
          @record = @collection.terms.find(params[:term_id])
        end
      end
    end
  end
end
