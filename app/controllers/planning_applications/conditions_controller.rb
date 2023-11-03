# frozen_string_literal: true

module PlanningApplications
  class ConditionsController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_condition_set

    def index
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
          if update_condition_set
            redirect_to planning_application_assessment_tasks_path(@planning_application),
              notice: I18n.t("conditions.update.success")
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

    def condition_params
      params.require(:condition_set)
        .permit(
          conditions: [],
          conditions_attributes: %i[_destroy id standard title text reason]
        )
        .to_h.merge(status:)
    end

    def status
      mark_as_complete? ? :complete : :in_progress
    end

    def update_condition_set
      ActiveRecord::Base.transaction do
        @condition_set.update(condition_params.except(:conditions)) && update_condition_set_review!
      end
    end

    def update_condition_set_review!
      (!@condition_set.review.not_started?) ? condition_set_review_status_updated! : true
    end

    def condition_set_review_status_updated!
      if @condition_set.complete? && @condition_set.review.to_be_reviewed? && mark_as_complete?
        @condition_set.review.updated!
      end
    end
  end
end
