# frozen_string_literal: true

module PlanningApplications
  module Review
    class RecommendationsController < BaseController
      before_action :ensure_user_is_reviewer_checking_assessment, only: %i[update edit]
      before_action :set_recommendations, only: %i[update edit]
      before_action :set_committee_decision
      before_action :set_recommendation, only: :update

      def new
        @recommendation = Recommendation.new
      end

      def edit
        @recommendation = @recommendations.last

        respond_to do |format|
          format.html
        end
      end

      def create
        @recommendation = @planning_application.recommendations.new(
          status: "review_complete",
          assessor: Current.user,
          reviewer: Current.user
        )

        if @recommendation.save_and_submit(recommendation_form_params)
          redirect_to planning_application_review_tasks_path(@planning_application, anchor: "recommendation_to_committee_section"), notice: t(".success")
        else
          render :new
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @recommendation.save_and_review(recommendation_params)
              redirect_to after_save_and_review_location_url, notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      private

      def set_recommendations
        @recommendations = @planning_application.recommendations
      end

      def set_recommendation
        @recommendation = @planning_application.recommendations.find(recommendation_id)
      end

      def set_committee_decision
        @committee_decision = @planning_application.committee_decision
      end

      def recommendation_id
        Integer(params[:id])
      end

      def recommendation_params
        params
          .require(:recommendation)
          .permit(:reviewer_comment, :challenged)
          .merge(status: recommendation_status, committee_overturned: committee_overturned_status)
      end

      def recommendation_status
        save_progress? ? :review_in_progress : :review_complete
      end

      def recommendation_form_params
        params
          .require(:recommendation)
          .permit(:decision, :public_comment)
          .merge(assessor: current_user, status: :review_complete)
      end

      def render_failed_edit(error)
        flash.now[:alert] = error.message

        render :edit
      end

      def committee_overturned_status
        params[:recommendation][:challenged] == "committee_overturned"
      end

      def after_save_and_review_location_url
        if @recommendation.committee_overturned?
          new_planning_application_review_recommendation_path(@planning_application)
        else
          planning_application_review_tasks_path(@planning_application)
        end
      end
    end
  end
end
