# frozen_string_literal: true

module PlanningApplications
  module Review
    class ConsiderationsController < BaseController
      before_action :set_consideration_set
      before_action :set_considerations
      before_action :set_review

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @review.update(review_params)
              redirect_to tasks_url(anchor: "review-considerations", next: true), notice: t(".success")
            else
              @show_header_bar = false
              render :tasks, alert: t(".failure_html")
            end
          end
        end
      end

      private

      def set_consideration_set
        @consideration_set = @planning_application.consideration_set
      end

      def set_considerations
        @considerations = @consideration_set.considerations
      end

      def set_review
        @review = @consideration_set.current_review
      end

      def review_params
        params.require(:review_considerations)
          .permit(:action, :comment, :review_status)
          .merge(reviewer: current_user, reviewed_at: Time.current)
      end
    end
  end
end
