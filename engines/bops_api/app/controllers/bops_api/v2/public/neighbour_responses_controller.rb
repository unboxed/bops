# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class NeighbourResponsesController < PublicController
        def index
          @planning_application = find_planning_application params[:planning_application_id]
          @consultation = @planning_application.consultation

          @neighbour_responses = if @consultation
            @consultation.neighbour_responses.redacted
          else
            NeighbourResponse.none
          end

          @pagy, @comments = BopsApi::Postsubmission::CommentsPublicService.new(
            @neighbour_responses,
            pagination_params
          ).call

          @total_available_items = @neighbour_responses.count
          @response_summary = @neighbour_responses.group(:summary_tag).count
          @response_summary = {
            supportive: @response_summary["supportive"] || 0,
            objection: @response_summary["objection"] || 0,
            neutral: @response_summary["neutral"] || 0
          }

          respond_to do |format|
            format.json
          end
        end

        private

        # Permit and return the required parameters
        def pagination_params
          params.permit(:sortBy, :orderBy, :resultsPerPage, :query, :page, :format, :planning_application_id)
        end
      end
    end
  end
end
