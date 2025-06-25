# frozen_string_literal: true

module PlanningApplications
  module Review
    module PreCommencementConditions
      class PositionsController < BaseController
        include BopsCore::PositionsController

        private

        def set_collection
          @collection = @planning_application.pre_commencement_condition_set
        end

        def set_record
          @record = @collection.conditions.find(params[:item_id])
        end
      end
    end
  end
end
