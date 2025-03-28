# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class InformativesController < BaseController
      before_action :set_informative_set
      before_action :set_informatives
      before_action :set_informative
      before_action :set_review
      before_action :ensure_planning_application_is_not_preapp

      def create
        respond_to do |format|
          format.html do
            if @informative.update(informative_params)
              redirect_to edit_planning_application_assessment_informatives_path(@planning_application), notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def show
        respond_to do |format|
          format.html do
            if @review.complete?
              render :show
            else
              redirect_to edit_planning_application_assessment_informatives_path(@planning_application)
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
            if @informative_set.update_review(review_params)
              redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
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
        @informatives = @informative_set.informatives.select(&:persisted?)
      end

      def set_informative
        @informative = @informative_set.informatives.new
      end

      def informative_params
        params.require(:informative).permit(:title, :text)
      end

      def set_review
        @review = @informative_set.current_review
      end

      def review_params
        params.require(:review).permit(:status).merge(assessor: current_user)
      end
    end
  end
end
