# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class RecommendationsController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :ensure_user_is_reviewer_checking_assessment, only: %i[update edit]
      before_action :set_recommendations, only: %i[update edit]
      before_action :set_recommendation, only: :update

      rescue_from Recommendation::ReviewRecommendationError do |error|
        render_failed_edit(error)
      end

      def new
        @recommendation = RecommendationForm.new(
          recommendation: @planning_application.existing_or_new_recommendation
        )
      end

      def edit
        @recommendation = @recommendations.last

        respond_to do |format|
          format.html
        end
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

      def update
        respond_to do |format|
          @recommendation.assign_attributes(recommendation_params)
          render :edit and return unless @recommendation.valid?

          if @recommendation.review_complete?
            @recommendation.review!
          else
            @recommendation.save!
          end

          format.html do
            redirect_to planning_application_review_tasks_path(@planning_application),
              notice: t(".success")
          end
        end
      end

      private

      def planning_applications_scope
        if action_name.in?(%w[edit update])
          super.includes(:recommendations)
        else
          super
        end
      end

      def set_recommendations
        @recommendations = @planning_application.recommendations
      end

      def set_recommendation
        @recommendation = @planning_application.recommendations.find(recommendation_id)
      end

      def recommendation_id
        Integer(params[:id])
      end

      def recommendation_params
        params
          .require(:recommendation)
          .permit(:reviewer_comment, :challenged)
          .merge(status: recommendation_status)
      end

      def recommendation_status
        save_progress? ? :review_in_progress : :review_complete
      end

      def recommendation_form_params
        params
          .require(:recommendation_form)
          .permit(:decision, :public_comment, :assessor_comment)
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
