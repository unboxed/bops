# frozen_string_literal: true

module PlanningApplications
  module Review
    class NeighbourResponsesController < BaseController
      rescue_from ::Review::NotCreatableError, with: :redirect_failed_create_error

      before_action :set_consultation
      before_action :set_neighbour_review

      def show
        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @neighbour_review.update(review_params) && @consultation.update(status: consultation_status)
              redirect_to planning_application_review_tasks_path(@planning_application), notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      def create
        @neighbour_review = @consultation.neighbour_reviews.new(review_params)

        respond_to do |format|
          format.html do
            if @neighbour_review.save && @consultation.update(status: consultation_status)
              redirect_to planning_application_review_tasks_path(@planning_application), notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      private

      def review_params
        params.require(:review).permit(
          :action, :comment, :id
        ).merge(
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

      def consultation_status
        if return_to_officer?
          :to_be_reviewed
        else
          @consultation.status
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
