# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class ConsulteeResponsesController < PublicController
        def index
          @planning_application = find_planning_application params[:planning_application_id]
          @consultation = @planning_application.consultation

          if @consultation
            consultation_consultees = @consultation.consultees.includes(:responses)
            redacted_responses = @consultation.consultee_responses.redacted
          else
            consultation_consultees = Consultee.none
            redacted_responses = Consultee::Response.none
            @total_consulted = 0
          end

          latest_redacted_responses = consultation_consultees
            .map { |consultee| consultee.responses.redacted.max_by(&:id) }
            .compact

          summary_counts = latest_redacted_responses
            .group_by(&:summary_tag)
            .transform_values(&:size)
          @total_comments = summary_counts.values.sum

          @response_summary = {
            approved: summary_counts["approved"] || 0,
            objected: summary_counts["objected"] || 0,
            amendments_needed: summary_counts["amendments_needed"] || 0
          }

          @total_available_items = redacted_responses.count
          @total_consulted ||= consultation_consultees.consulted.count

          @pagy, @comments = BopsApi::Postsubmission::CommentsSpecialistService.new(
            redacted_responses,
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
