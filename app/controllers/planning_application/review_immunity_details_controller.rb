# frozen_string_literal: true

class PlanningApplication
  class ReviewImmunityDetailsController < AuthenticationController
    include CommitMatchable
    include PlanningApplicationAssessable

    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated
    before_action :set_immunity_detail, only: %i[show edit update]

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
      @immunity_detail.assign_attributes(
        review_status:, reviewer: current_user, reviewed_at: Time.current
      )

      respond_to do |format|
        if @immunity_detail.update(immunity_detail_params)
          format.html do
            redirect_to planning_application_review_tasks_path(@planning_application),
                        notice: I18n.t("immunity_details.successfully_updated")
          end
        else
          set_immunity_detail
          format.html { render :edit }
        end
      end
    end

    private

    def immunity_detail_params
      params.require(:immunity_detail)
            .permit(:reviewer_comment)
            .to_h
            .deep_merge(status: immunity_detail_status)
    end

    def review_status
      save_progress? ? "review_in_progress" : "review_complete"
    end

    def set_immunity_detail
      @immunity_detail = @planning_application.immunity_detail
    end

    def immunity_detail_status
      return_to_officer? ? :to_be_reviewed : :complete
    end

    def return_to_officer?
      params.dig(:immunity_detail, :mark) == "return_to_officer_with_comment"
    end
  end
end
