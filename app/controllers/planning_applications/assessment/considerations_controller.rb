# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConsiderationsController < BaseController
      before_action :set_consideration_set
      before_action :set_considerations
      before_action :set_consideration
      before_action :set_review

      def create
        @consideration.submitted_by = current_user

        respond_to do |format|
          format.html do
            if @consideration.update(consideration_params, :assess)
              redirect_to edit_planning_application_assessment_considerations_path(@planning_application), notice: t(".success")
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
              redirect_to edit_planning_application_assessment_considerations_path(@planning_application)
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
        @consideration.submitted_by = current_user

        respond_to do |format|
          format.html do
            if @consideration_set.update_review(review_params)
              redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
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
        @considerations = @consideration_set.considerations.select(&:persisted?)
      end

      def set_consideration
        @consideration = @consideration_set.considerations.new
      end

      def consideration_params
        params.require(:consideration).permit(
          :policy_area, :assessment, :conclusion,
          policy_references_attributes: %i[code description url],
          policy_guidance_attributes: %i[description url]
        )
      end

      def set_review
        @review = @consideration_set.current_review
      end

      def review_params
        params.require(:review).permit(:status).merge(assessor: current_user)
      end
    end
  end
end
