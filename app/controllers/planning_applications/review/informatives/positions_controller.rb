# frozen_string_literal: true

module PlanningApplications
  module Review
    module Informatives
      class PositionsController < BaseController
        include BopsCore::PositionsController

        private

        def set_collection
          @collection = @planning_application.informative_set
        end

        def set_record
          @record = @collection.informatives.find(params[:item_id])
        end
      end
    end
  end
end
