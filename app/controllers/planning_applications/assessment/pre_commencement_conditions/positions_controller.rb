# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module PreCommencementConditions
      class PositionsController < AuthenticationController
        before_action :set_planning_application
        before_action :set_condition_set
        before_action :set_condition

        def update
          if @condition.insert_at(pre_commencement_condition_position)
            head :no_content
          else
            render json: @condition.errors, status: :unprocessable_entity
          end
        end

        private

        def set_condition
          @condition = @condition_set.conditions.find(params[:pre_commencement_condition_id])
        end

        def set_condition_set
          @condition_set = @planning_application.pre_commencement_condition_set
        end

        def pre_commencement_condition_params
          params.require(:condition).permit(:position)
        end

        def pre_commencement_condition_position
          Integer(pre_commencement_condition_params[:position])
        end
      end
    end
  end
end
