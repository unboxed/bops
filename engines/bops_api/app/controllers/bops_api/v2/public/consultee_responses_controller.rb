# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class ConsulteeResponsesController < PublicController
        include ParamHelpers

        def index
          @planning_application = find_planning_application params[:planning_application_id]
          @consultation = @planning_application.consultation
          unless @consultation
            render json: {error: {message: "Bad Request", detail: "Consultation not found"}}, status: :bad_request
            return
          end

          consultation_consultees = @consultation.consultees.includes(:responses)

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
          redacted_responses = @consultation.consultee_responses.redacted.includes(consultee: {planning_application_constraints: :constraint})

          @total_available_items = redacted_responses.count
          @total_consulted ||= consultation_consultees.consulted.count

          @pagy, @comments = BopsApi::Postsubmission::CommentsSpecialistService.new(
            redacted_responses,
            pagination_params
          ).call

          grouped_comments = @comments.group_by(&:consultee)
          @specialists = grouped_comments.map do |consultee, responses|
            BopsApi::V2::Public::Postsubmission::SpecialistCommentPresenter.new(consultee, responses)
          end

          respond_to do |format|
            format.json
          end
        end

        private

        # Permit and return the required parameters
        def pagination_params
          permitted = params.permit(:sortBy, :orderBy, :resultsPerPage, :query, :page, :format, :planning_application_id, :sentiment)
          if permitted[:sentiment].present?
            permitted[:sentiment] = handle_comma_separated_param(permitted[:sentiment])
          end
          permitted
        end
      end
    end
  end
end
