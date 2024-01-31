# frozen_string_literal: true

module PlanningApplications
  module Review
    class ConditionsController < AuthenticationController
      include CommitMatchable
      include PlanningApplicationAssessable

      before_action :set_planning_application
      before_action :ensure_planning_application_is_validated
      before_action :ensure_user_is_reviewer
      before_action :set_condition_set

      def show
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @condition_set.update(condition_set_review_params)
              redirect_to planning_application_review_tasks_path(@planning_application),
                notice: I18n.t("review.conditions.update.success")
            else
              render :edit
            end
          end
        end
      end

      private

      def set_condition_set
        @condition_set = @planning_application.condition_set
      end

      def condition_set_review_params
        params.require(:condition_set)
          .permit(review_attributes: %i[action comment],
            conditions_attributes: %i[_destroy id standard title text reason])
          .to_h
          .deep_merge(
            status: condition_set_status,
            review_attributes: {
              reviewed_at: Time.current,
              reviewer: current_user,
              status: status,
              review_status:
            }
          )
      end

      def status
        if mark_as_complete?
          :complete
        elsif save_progress? || return_to_officer?
          :in_progress
        elsif return_to_officer?
          :to_be_reviewed
        end
      end

      def condition_set_status
        if return_to_officer?
          :to_be_reviewed
        else
          @condition_set.status
        end
      end

      def review_status
        save_progress? ? "review_in_progress" : "review_complete"
      end

      def return_to_officer?
        params.dig(:condition_set, :review_attributes, :action) == "rejected"
      end
    end
  end
end
