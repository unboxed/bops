# frozen_string_literal: true

module PlanningApplications::Review
  class PreCommencementConditionsController < BaseController
    def show
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        format.html do
          if condition_set.update(review_params)
            redirect_to planning_application_review_tasks_path(@planning_application),
              notice: I18n.t("review.conditions.update.success")
          else
            render :show
          end
        end
      end
    end

    private

    def condition_set
      @planning_application.pre_commencement_condition_set
    end

    def review_complete?
      condition_set&.current_review&.complete_or_to_be_reviewed?
    end

    def review_params
      params.require(:condition_set)
        .permit(reviews_attributes: %i[action comment],
          conditions_attributes: %i[_destroy id standard title text reason])
        .to_h
        .deep_merge(
          reviews_attributes: {
            reviewed_at: Time.current,
            reviewer: current_user,
            status: status,
            review_status:,
            id: condition_set&.current_review&.id
          }
        )
    end

    def status
      if return_to_officer?
        :to_be_reviewed
      elsif save_progress?
        :in_progress
      elsif mark_as_complete?
        :complete
      end
    end

    def review_status
      save_progress? ? :review_in_progress : :review_complete
    end

    def return_to_officer?
      params.dig(:condition_set, :reviews_attributes, :action) == "rejected"
    end

    helper_method :condition_set, :review_complete?
  end
end
