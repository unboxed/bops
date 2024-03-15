# frozen_string_literal: true

module PlanningApplications
  module Review
    class CommitteeDecisionsController < AuthenticationController
      include CommitMatchable
      before_action :set_planning_application
      before_action :ensure_user_is_reviewer
      before_action :set_committee_decision

      def edit
      end

      def show
      end

      def update
        if @committee_decision.update!(committee_decision_params)
          redirect_to planning_application_review_tasks_path(@planning_application)
        else
          render :edit
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
              status: status,
              review_status:,
              id: @condition_set&.current_review&.id
            }
          )
      end

      def status
        if return_to_officer?
          "to_be_reviewed"
        elsif save_progress?
          "in_progress"
        elsif mark_as_complete?
          "complete"
        end
      end

      def return_to_officer?
        params.dig(:committee_decision, :reviews_attributes, :action) == "rejected"
      end

      def review_status
        save_progress? ? "review_in_progress" : "review_complete"
      end
    end
  end
end
