# frozen_string_literal: true

module BopsReports
  module PlanningApplications
    class RecommendationsController < ApplicationController
      include CommitMatchable
      before_action :set_planning_application

      def new
        @recommendation = @planning_application.recommendations.new
      end

      def create
        @recommendation = @planning_application.recommendations.new(recommendation_params)
        if @recommendation.save
          redirect_to planning_application_path(@planning_application), notice: "Recommendation submitted."
        else
          render :new
        end
      end

      private

      def set_planning_application
        @planning_application = PlanningApplication.find_by!(reference: params[:planning_application_reference])
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

      def committee_overturned_status
        params[:recommendation][:challenged] == "committee_overturned"
      end
    end
  end
end
