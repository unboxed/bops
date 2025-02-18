# frozen_string_literal: true

module PlanningApplications
  module Review
    class NeighbourResponsesController < BaseController
      rescue_from ::Review::NotCreatableError, with: :redirect_failed_create_error

      before_action :set_consultation
      before_action :set_neighbour_review

      def update
        respond_to do |format|
          format.html do
            if @neighbour_review.update(review_params) && @consultation.update(status: consultation_status)
              redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-neighbour-responses"), notice: t(".success")
            else
              error = @neighbour_review.errors.group_by_attribute.transform_values { |errors| errors.map(&:full_message) }.values.flatten
              redirect_failed_create_error(error)
            end
          end
        end
      end

      def create
        @neighbour_review = @consultation.neighbour_reviews.new(review_params)

        respond_to do |format|
          format.html do
            if @neighbour_review.save && @consultation.update(status: consultation_status)
              redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-neighbour-responses"), notice: t(".success")
            else
              error = @neighbour_review.errors.group_by_attribute.transform_values { |errors| errors.map(&:full_message) }.values.flatten
              redirect_failed_create_error(error)
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
          review_status: "review_complete",
          status:
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

      def set_neighbour_review
        @neighbour_review = @consultation.neighbour_review || @consultation.reviews.new
      end
    end
  end
end
