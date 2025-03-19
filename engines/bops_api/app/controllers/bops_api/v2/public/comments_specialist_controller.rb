# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class CommentsSpecialistController < PublicController
        def index
          @planning_application = find_planning_application params[:planning_application_id]
          @consultation = @planning_application.consultation
          if @consultation.nil?
            raise BopsApi::Errors::InvalidRequestError, "Consultation not found"
          end
          @consultee_responses = @consultation.consultee_responses.redacted

          @total_responses = @consultee_responses.count
          @total_consulted = @consultation.consultees.count

          @response_summary = @consultee_responses.group(:summary_tag)
            .unscope(:order) # Remove default ORDER BY clause
            .count
          @response_summary = {
            supportive: @response_summary["approved"] || 0,
            objection: @response_summary["objected"] || 0,
            neutral: @response_summary["amendments_needed"] || 0
          }

          @pagy, @comments = BopsApi::CommentsSpecialistService.new(
            @consultee_responses,
            pagination_params
          ).call

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
