# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module Considerations
      class PositionsController < BaseController
        include BopsCore::PositionsController

        private

        def set_collection
          @collection = @planning_application.consideration_set
        end

        def set_record
          @record = @collection.considerations.find(params[:item_id])
        end
      end
    end
  end
end
