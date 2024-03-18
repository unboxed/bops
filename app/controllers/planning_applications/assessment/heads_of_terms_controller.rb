# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class HeadsOfTermsController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_heads_of_terms
      before_action :set_heads_of_term, only: %i[edit]

      def index
        respond_to do |format|
          format.html
        end
      end

      def new
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @heads_of_term.update(heads_of_terms_params)
              redirect_to planning_application_assessment_tasks_path(@planning_application),
                notice: I18n.t("heads_of_terms.update.success")
            else
              render :index
            end
          end
        end
      end

      private

      def set_heads_of_terms
        @heads_of_term = @planning_application.heads_of_term
      end

      def heads_of_term_id
        Integer(params[:heads_of_term_id])
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid heads of terms id: #{params[:heads_of_term_id].inspect}"
      end

      def set_heads_of_term
        @term = @heads_of_term.terms.find(heads_of_term_id)
      end

      def heads_of_terms_params
        params.require(:heads_of_term)
          .permit(
            terms_attributes: %i[_destroy id title text]
          ).to_h.merge(reviews_attributes: [status:, id: (@heads_of_term&.current_review&.id if !mark_as_complete?)])
      end

      def status
        if mark_as_complete?
          if @heads_of_term.current_review.present? && @heads_of_term.current_review.status == "to_be_reviewed"
            "updated"
          else
            "complete"
          end
        else
          "in_progress"
        end
      end
    end
  end
end
