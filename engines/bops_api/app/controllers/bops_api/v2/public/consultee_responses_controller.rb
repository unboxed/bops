# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class ConsulteeResponsesController < PublicController
        def index
          @planning_application = find_planning_application params[:planning_application_id]
          @consultation = @planning_application.consultation
          if @consultation.nil?
            raise BopsApi::Errors::InvalidRequestError, "Consultation not found"
          end
          @consultee_responses = @consultation.consultee_responses.redacted

          @total_responses = @consultee_responses.count
          @total_consulted = @consultation.consultees.consulted.count

          # gets last redacted response
          @response_summary = @consultation.consultees.map { |c| c.responses.redacted.max_by(&:id) }.compact.group_by(&:summary_tag).transform_values(&:count)
          @total_comments = @response_summary.values.sum
          @response_summary = {
            approved: @response_summary["approved"] || 0,
            objected: @response_summary["objected"] || 0,
            amendments_needed: @response_summary["amendments_needed"] || 0
          }

          @pagy, @comments = BopsApi::Postsubmission::CommentsSpecialistService.new(
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
