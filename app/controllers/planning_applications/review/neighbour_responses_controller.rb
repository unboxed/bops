# frozen_string_literal: true

module PlanningApplications
  module Review
    class NeighbourResponsesController < AuthenticationController
      include CommitMatchable

      rescue_from ::Review::NotCreatableError, with: :redirect_failed_create_error

      before_action :set_planning_application
      before_action :set_consultation
      before_action :set_neighbour_review

      def index
      end

      def update
        respond_to do |format|
          format.html do
            if @neighbour_review.update(review_params)
              redirect_to planning_application_review_tasks_path(@planning_application), notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      def create
        @neighbour_review = @consultation.reviews.new(review_params.merge(specific_attributes: {consultation_type: "neighbour"}))

        respond_to do |format|
          format.html do
            if @neighbour_review.save
              redirect_to planning_application_review_tasks_path(@planning_application), notice: t(".success")
            else
              render :index
            end
          end
        end
      end

      private

      def review_params
        params.require(:review).permit(
          :action, :comment, :id
        ).to_h
          .deep_merge(
            reviewed_at: Time.current,
            reviewer: current_user,
            status:,
            review_status:
          )
      end

      def status
        if return_to_officer?
          :to_be_reviewed
        elsif mark_as_complete?
          :complete
        end
      end

      def return_to_officer?
        params.dig(:review, :action) == "rejected"
      end

      def review_status
        save_progress? ? "review_in_progress" : "review_complete"
      end

      def set_neighbour_review
        @neighbour_review = @consultation.neighbour_review || @consultation.reviews.new
      end

      def redirect_failed_create_error(error)
        redirect_to planning_application_review_tasks_path(@planning_application), alert: error.message
      end
    end
  end
end