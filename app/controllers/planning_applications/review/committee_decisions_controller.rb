# frozen_string_literal: true

module PlanningApplications
  module Review
    class CommitteeDecisionsController < BaseController
      before_action :set_committee_decision

      def edit
      end

      def show
      end

      def update
        respond_to do |format|
          format.html do
            if @committee_decision.update(committee_decision_params)
              redirect_to planning_application_review_tasks_path(@planning_application, anchor: "recommendation_to_committee_section"), notice: t(".success")
            else
              flash.now[:alert] = @committee_decision.errors.messages.values.flatten.join(", ")
              render_review_tasks
            end
          end
        end
      end

      private

      def set_committee_decision
        @committee_decision = @planning_application.committee_decision
      end

      def committee_decision_params
        params.require(:committee_decision).permit(
          reviews_attributes: %i[comment action]
        ).to_h
          .deep_merge(
            reviews_attributes: {
              reviewed_at: Time.current,
              reviewer: current_user,
              status:,
              review_status:,
              id: @committee_decision.current_review.id
            }
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
        params.dig(:committee_decision, :reviews_attributes, :action) == "rejected"
      end

      def review_status
        save_progress? ? :review_in_progress : :review_complete
      end
    end
  end
end
