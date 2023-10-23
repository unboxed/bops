# frozen_string_literal: true

module PlanningApplications
  module Review
    class ImmunityDetailsController < AuthenticationController
      include CommitMatchable
      include PlanningApplicationAssessable

      before_action :set_planning_application
      before_action :ensure_planning_application_is_validated
      before_action :ensure_user_is_reviewer
      before_action :set_immunity_detail, only: %i[show edit update]
      before_action :set_review_immunity_detail, only: %i[show edit update]

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
        @immunity_detail.assign_attributes(review_status:)

        respond_to do |format|
          if update_immunity_details
            format.html do
              redirect_to planning_application_review_tasks_path(@planning_application),
                          notice: I18n.t("immunity_details.successfully_updated")
            end
          else
            set_immunity_detail
            set_review_immunity_detail
            format.html { render :edit }
          end
        end
      end

      private

      def update_immunity_details
        ActiveRecord::Base.transaction do
          @immunity_detail.update(status: immunity_detail_status) &&
            @review_immunity_detail.update(review_immunity_detail_params)
        end
      end

      def review_immunity_detail_params
        params.require(:review_immunity_detail)
              .permit(:reviewer_comment, :accepted)
              .to_h
              .deep_merge(reviewed_at: Time.current, reviewer: current_user)
      end

      def review_status
        save_progress? ? "review_in_progress" : "review_complete"
      end

      def set_immunity_detail
        @immunity_detail = @planning_application.immunity_detail
      end

      def set_review_immunity_detail
        @review_immunity_detail = @immunity_detail.current_evidence_review_immunity_detail
      end

      def immunity_detail_status
        return_to_officer? ? :to_be_reviewed : :complete
      end

      def return_to_officer?
        params.dig(:review_immunity_detail, :accepted) == "false"
      end

      def ensure_user_is_reviewer
        current_user.reviewer?
      end
    end
  end
end
