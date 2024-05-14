# frozen_string_literal: true

module PlanningApplications
  module Assessment
    module Terms
      class PositionsController < AuthenticationController
        before_action :set_planning_application
        before_action :set_heads_of_term
        before_action :set_term

        def update
          if @term.insert_at(term_position)
            head :no_content
          else
            render json: @term.errors, status: :unprocessable_entity
          end
        end

        private

        def set_heads_of_term
          @heads_of_term = @planning_application.heads_of_term
        end

        def set_term
          @term = @heads_of_term.terms.find(params[:term_id])
        end

        def term_params
          params.require(:term).permit(:position)
        end

        def term_position
          Integer(term_params[:position])
        end
      end
    end
  end
end
