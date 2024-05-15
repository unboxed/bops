# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module Informatives
      class PositionsController < AuthenticationController
        include BopsCore::PositionsController

        private

        def set_collection
          @collection = @planning_application.informative_set
        end

        def set_record
          @record = @collection.informatives.find(params[:informative_id])
        end
      end
    end
  end
end
