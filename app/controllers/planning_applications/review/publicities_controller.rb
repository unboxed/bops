# frozen_string_literal: true

module PlanningApplications
  module Review
    class PublicitiesController < BaseController
      before_action :set_consultation
      before_action :set_press_notice
      before_action :set_site_notice
      before_action :set_assessment_detail
      before_action :set_task, only: %i[update]

      def update
        respond_to do |format|
          format.html do
            if @assessment_detail.update(assessment_detail_params)
              reset_assessment_tasks! if return_to_officer?

              redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-publicities"), notice: t(".success")
            else
              flash.now[:alert] = @assessment_detail.errors.messages.values.flatten.join(", ")
              render_review_tasks
            end
          end
        end
      end

      def create
        @assessment_detail.assign_attributes(assessment_detail_params)

        respond_to do |format|
          format.html do
            if @assessment_detail.save
              redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-publicities"), notice: t(".success")
            else
              flash.now[:alert] = @assessment_detail.errors.messages.values.flatten.join(", ")
              render_review_tasks
            end
          end
        end
      end

      private

      def assessment_detail_params
        params.require(:assessment_detail).permit(
          :reviewer_verdict, comment_attributes: [:text]
        ).merge(review_status: :complete, assessment_status:)
      end

      def return_to_officer?
        params.dig(:review, :action) == "rejected"
      end

      def set_assessment_detail
        @assessment_detail = @planning_application.existing_or_new_check_publicity
      end

      def set_site_notice
        @site_notice = @planning_application.site_notice
      end

      def set_press_notice
        @press_notice = @planning_application.press_notice
      end

      def set_task
        @task = @planning_application.case_record.find_task_by_slug_path("check-and-assess/assessment-summaries/check-publicity")
      end
    end
  end
end
