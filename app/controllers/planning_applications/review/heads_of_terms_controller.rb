# frozen_string_literal: true

module PlanningApplications
  module Review
    class HeadsOfTermsController < BaseController
      def show
        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if heads_of_term.update(review_params)
              redirect_to planning_application_review_tasks_path(@planning_application),
                notice: I18n.t("review.heads_of_terms.update.success")
            else
              render :show
            end
          end
        end
      end

      private

      def heads_of_term
        @planning_application.heads_of_term
      end

      def review_complete?
        heads_of_term&.current_review&.complete_or_to_be_reviewed?
      end

      def review_params
        params.require(:heads_of_term)
          .permit(reviews_attributes: %i[action comment],
            terms_attributes: %i[id standard title text])
          .to_h
          .deep_merge(
            reviews_attributes: {
              reviewed_at: Time.current,
              reviewer: current_user,
              status: status,
              review_status:,
              id: heads_of_term&.current_review&.id
            }
          )
      end

      def status
        if return_to_officer?
          :to_be_reviewed
        elsif save_progress?
          :in_progress
        elsif mark_as_complete?
          :complete
        end
      end

      def review_status
        save_progress? ? :review_in_progress : :review_complete
      end

      def return_to_officer?
        params.dig(:condition_set, :reviews_attributes, :action) == "rejected"
      end

      helper_method :heads_of_term, :review_complete?
    end
  end
end
