# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class RecommendationsController < BaseController
      before_action :set_committee_decision
      before_action :ensure_planning_application_is_not_preapp

      rescue_from Recommendation::ReviewRecommendationError do |error|
        render_failed_edit(error)
      end

      def new
        @recommendation = RecommendationForm.new(
          recommendation: @planning_application.existing_or_new_recommendation
        )
      end

      def create
        @recommendation = RecommendationForm.new(
          recommendation: @planning_application.pending_or_new_recommendation,
          **recommendation_form_params
        )

        if @recommendation.save
          redirect_to planning_application_assessment_tasks_path(@planning_application)
        else
          render :new
        end
      end

      private

      def set_committee_decision
        @committee_decision = @planning_application.committee_decision
      end

      def recommendation_form_params
        params
          .require(:recommendation_form)
          .permit(:decision, :public_comment, :assessor_comment, :recommend, :other_reason, reasons: [])
          .merge(assessor: current_user, status: recommendation_form_status)
      end

      def recommendation_form_status
        save_progress? ? :assessment_in_progress : :assessment_complete
      end

      def render_failed_edit(error)
        flash.now[:alert] = error.message

        render :edit
      end
    end
  end
end
