# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class NeighbourResponsesController < PublicController
        def index
          @planning_application = find_planning_application params[:planning_application_id]
          @consultation = @planning_application.consultation
          if @consultation.nil?
            raise BopsApi::Errors::InvalidRequestError, "Consultation not found"
          end
          @neighbour_responses = @consultation.neighbour_responses.redacted

          raw_query_string = request.env["QUERY_STRING"]
          sentiments = extract_sentiments_from_query(raw_query_string)
          updated_params = pagination_params.to_h.merge(sentiment: sentiments)

          @pagy, @comments = BopsApi::Postsubmission::CommentsPublicService.new(
            @neighbour_responses,
            updated_params
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
          params.permit(:sortBy, :orderBy, :resultsPerPage, :query, :page, :format, :planning_application_id, :sentiment)
        end

        def extract_sentiments_from_query(query_string)
          # Use a regular expression to find all occurrences of the sentiment parameter
          query_string.scan(/sentiment=([^&]*)/).flatten
        end
      end
    end
  end
end
