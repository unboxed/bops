# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module Informatives
      class PositionsController < AuthenticationController
        before_action :set_planning_application
        before_action :set_informative_set
        before_action :set_informative

        def update
          if @informative.insert_at(informative_position)
            head :no_content
          else
            render json: @informative.errors, status: :unprocessable_entity
          end
        end

        private

        def set_informative_set
          @informative_set = @planning_application.informative_set
        end

        def set_informative
          @informative = @informative_set.informatives.find(params[:informative_id])
        end

        def informative_position_params
          params.require(:informative).permit(:position)
        end

        def informative_position
          Integer(informative_position_params[:position])
        end
      end
    end
  end
end
