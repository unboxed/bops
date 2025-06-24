# frozen_string_literal: true

module PlanningApplications
  module Review
    class HeadsOfTermsController < BaseController
      before_action :redirect_to_review_tasks, unless: :heads_of_terms_enabled?

      before_action :set_heads_of_terms
      before_action :set_terms
      before_action :set_review

      before_action :redirect_to_review_tasks, if: :heads_of_terms_not_started?

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @review.update(review_params)
              redirect_to tasks_url(anchor: "review-heads-of-terms", next: true), notice: t(".success")
            else
              render :tasks, alert: t(".failure_html")
            end
          end
        end
      end

      private

      def set_heads_of_terms
        @heads_of_terms = @planning_application.heads_of_term
      end

      def set_terms
        @terms = @heads_of_terms.terms.not_cancelled
      end

      def set_review
        @review = @heads_of_terms.current_review
      end

      def review_params
        params.require(:review_heads_of_terms)
          .permit(:action, :comment, :review_status)
          .merge(reviewer: current_user, reviewed_at: Time.current)
      end

      def heads_of_terms_enabled?
        @planning_application.heads_of_terms?
      end

      def heads_of_terms_not_started?
        @review.not_started?
      end
    end
  end
end
