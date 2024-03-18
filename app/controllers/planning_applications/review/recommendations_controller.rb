# frozen_string_literal: true

module PlanningApplications
  module Review
    class RecommendationsController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_recommendations, only: %i[update edit]
      before_action :set_committee_decision
      before_action :set_recommendation, only: :update
      before_action :set_committee, only: :edit

      rescue_from Recommendation::ReviewRecommendationError do |error|
        render_failed_edit(error)
      end

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
        @recommendation = Recommendation.new(recommendation_params.except(:decision, :public_comment))

        if @recommendation.save && @recommendation.review_complete?
          @recommendation.review!
          redirect_to planning_application_review_tasks_path(@planning_application)
        else
          render :new
        end
      end

      def update
        respond_to do |format|
          @recommendation.assign_attributes(recommendation_params)
          render :edit and return unless @recommendation.valid?

          if @recommendation.review_complete?
            @planning_application.update!(decision: recommendation_params[:decision], public_comment: recommendation_params[:public_comment])
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

      def set_committee_decision
        @committee_decision = @planning_application.committee_decision
      end

      def recommendation_id
        Integer(params[:id])
      end

      def recommendation_params
        params
          .require(:recommendation)
          .permit(:reviewer_comment, :challenged, :decision, :public_comment)
          .merge(
            status: recommendation_status, 
            planning_application_id: @planning_application.id,
            assessor: Current.user,
            reviewer: Current.user
          )
      end

      def recommendation_status
        save_progress? ? :review_in_progress : :review_complete
      end

      def render_failed_edit(error)
        flash.now[:alert] = error.message

        render :edit
      end

      def set_committee
        @in_committee = @planning_application.in_committee?
      end
    end
  end
end
