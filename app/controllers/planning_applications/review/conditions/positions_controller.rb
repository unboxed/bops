# frozen_string_literal: true

module PlanningApplications
  module Review
    module Conditions
      class PositionsController < BaseController
        include BopsCore::PositionsController

        private

        def set_collection
          @collection = @planning_application.condition_set
        end

        def set_record
          @record = @collection.conditions.find(params[:item_id])
        end
      end
    end
  end
end
