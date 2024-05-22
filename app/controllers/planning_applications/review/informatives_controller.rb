# frozen_string_literal: true

module PlanningApplications
  module Review
    class InformativesController < BaseController
      before_action :set_informative_set
      before_action :set_informatives
      before_action :set_review

      before_action :redirect_to_review_tasks, if: :informatives_not_started?

      def show
        respond_to do |format|
          format.html do
            if @review.review_complete?
              render :show
            else
              redirect_to edit_planning_application_review_informatives_path(@planning_application)
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
        params.require(:review)
          .permit(:action, :comment, :review_status)
          .merge(reviewer: current_user, reviewed_at: Time.current)
      end

      def redirect_to_review_tasks
        redirect_to planning_application_review_tasks_path(@planning_application)
      end

      def informatives_not_started?
        @review.not_started?
      end
    end
  end
end
