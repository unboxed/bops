# frozen_string_literal: true

module PlanningApplications
  module Review
    class AssessmentDetailsController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_consultation
      before_action :set_assessment_detail_review

      def show; end

      def edit; end

      def update
        @form.attributes = review_assessment_details_params

        if @form.save
          redirect_to(
            planning_application_review_tasks_path(@planning_application),
            notice: I18n.t("review_assessment_details.saved")
          )
        else
          render :edit
        end
      end

      private

      def set_assessment_detail_review
        @form = ReviewAssessmentDetailsForm.new(
          planning_application: @planning_application
        )
      end

      def review_assessment_details_params
        params
          .require(:review_assessment_details_form)
          .permit(permitted_attributes)
          .merge(status:)
      end

      def permitted_attributes
        ReviewAssessmentDetailsForm::ASSESSMENT_DETAILS.map do |assessment_detail|
          [
            "#{assessment_detail}_reviewer_verdict",
            "#{assessment_detail}_entry",
            "#{assessment_detail}_comment_text"
          ]
        end.flatten
      end

      def status
        mark_as_complete? ? :complete : :in_progress
      end
    end
  end
end
