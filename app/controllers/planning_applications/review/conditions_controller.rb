# frozen_string_literal: true

module PlanningApplications
  module Review
    class ConditionsController < BaseController
      before_action :set_condition_set
      before_action :set_conditions
      before_action :set_review

      before_action :redirect_to_review_tasks, if: :conditions_not_started?

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @review.update(review_params)
              redirect_to tasks_url(anchor: "review-conditions", next: true), notice: t(".success")
            else
              render :tasks, alert: t(".failure_html")
            end
          end
        end
      end

      private

      def set_condition_set
        @condition_set = @planning_application.condition_set
      end

      def set_conditions
        @conditions = @condition_set.conditions
      end

      def set_review
        @review = @condition_set.current_review
      end

      def review_params
        params.require(:review_conditions)
          .permit(:action, :comment, :review_status)
          .merge(reviewer: current_user, reviewed_at: Time.current)
      end

      def conditions_not_started?
        @review.not_started?
      end
    end
  end
end
