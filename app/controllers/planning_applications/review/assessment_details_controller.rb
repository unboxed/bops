# frozen_string_literal: true

module PlanningApplications
  module Review
    class AssessmentDetailsController < BaseController
      before_action :set_assessment_detail

      def update
        if @assessment_detail.update(review_assessment_details_params)
          redirect_to(
            planning_application_review_tasks_path(@planning_application),
            notice: t(".success", category: @assessment_detail.category.humanize.downcase)
          )
        else
          flash.now[:alert] = @assessment_detail.errors.messages.values.flatten.join(", ")
          render_review_tasks
        end
      end

      private

      def set_assessment_detail
        @assessment_detail = @planning_application.assessment_details.find(assessment_detail_id)
      end

      def assessment_detail_id
        Integer(params[:id])
      end

      def review_assessment_details_params
        params.require(:assessment_detail).permit(
          :reviewer_verdict,
          :entry,
          comment_attributes: [:text]
        ).merge(review_status: :complete)
      end
    end
  end
end
