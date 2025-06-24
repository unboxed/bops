# frozen_string_literal: true

module PlanningApplications
  module Review
    class InformativesController < BaseController
      before_action :set_informative_set
      before_action :set_informatives
      before_action :set_review

      before_action :redirect_to_review_tasks, if: :informatives_not_started?

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @review.update(review_params)
              redirect_to tasks_url(anchor: "review-informatives", next: true), notice: t(".success")
            else
              render :tasks, alert: t(".failure_html")
            end
          end
        end
      end

      private

      def set_informative_set
        @informative_set = @planning_application.informative_set
      end

      def set_informatives
        @informatives = @informative_set.informatives
      end

      def set_review
        @review = @informative_set.current_review
      end

      def review_params
        params.require(:review_informatives)
          .permit(:action, :comment, :review_status)
          .merge(reviewer: current_user, reviewed_at: Time.current)
      end

      def informatives_not_started?
        @review.not_started?
      end

      def sign_off_url
        edit_planning_application_review_recommendation_path(@planning_application, @planning_application.recommendation)
      end
    end
  end
end
