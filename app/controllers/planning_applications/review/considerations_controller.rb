# frozen_string_literal: true

module PlanningApplications
  module Review
    class ConsiderationsController < BaseController
      before_action :set_consideration_set
      before_action :set_considerations
      before_action :set_review

      before_action :redirect_to_review_tasks, if: :considerations_not_started?

      def show
        respond_to do |format|
          format.html do
            if @review.review_complete?
              render :show
            else
              redirect_to edit_planning_application_review_considerations_path(@planning_application)
            end
          end
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
            if @review.update(review_params)
              redirect_to planning_application_review_tasks_path(@planning_application), notice: t(".success")
            else
              render :edit
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
        params.require(:review)
          .permit(:action, :comment, :review_status)
          .merge(reviewer: current_user, reviewed_at: Time.current)
      end

      def redirect_to_review_tasks
        redirect_to planning_application_review_tasks_path(@planning_application)
      end

      def considerations_not_started?
        @review.not_started?
      end
    end
  end
end
