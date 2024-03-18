# frozen_string_literal: true

module PlanningApplications
  module Review
    class RecommendationsController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
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
        @recommendation = Recommendation.new(
          planning_application: @planning_application.planning_application,
          status: "review_complete",
          reviewer: Current.user
        )

        if @recommendation.save
          @planning_application.update!(decision: recommendation_form_params[:decision], public_comment: recommendation_form_params[:public_comment])
          @planning_application.submit!
          redirect_to planning_application_review_tasks_path(@planning_application), notice: t(".success")
        else
          render :new
        end
      end

      def update
        respond_to do |format|
          format.html do
            @recommendation.assign_attributes(recommendation_params)
            render :edit and return unless @recommendation.valid?

            if @recommendation.review_complete?
              @recommendation.review!
            else
              @recommendation.save!
            end

            if @recommendation.challenged?
              if @recommendation.committee_overturned?
                redirect_to new_planning_application_review_recommendation_path(@planning_application)
              else
                redirect_to planning_application_review_tasks_path(@planning_application),
                  notice: t(".success")
              end
            else
              redirect_to planning_application_review_tasks_path(@planning_application),
                notice: t(".success")
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
    end
  end
end
