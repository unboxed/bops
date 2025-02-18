# frozen_string_literal: true

module PlanningApplications::Review
  class PreCommencementConditionsController < BaseController
    before_action :set_pre_commencement_condition_set

    def show
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        format.html do
          if @pre_commencement_condition_set.update(review_params)
            redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-pre-commencement-conditions"),
              notice: I18n.t("review.conditions.update.success")
          else
            flash.now[:alert] = @pre_commencement_condition_set.errors.messages.values.flatten.join(", ")
            render_review_tasks
          end
        end
      end
    end

    private

    def set_pre_commencement_condition_set
      @pre_commencement_condition_set = @planning_application.pre_commencement_condition_set
    end

    def review_complete?
      @pre_commencement_condition_set&.current_review&.complete_or_to_be_reviewed?
    end

    def review_params
      params.require(:pre_commencement_condition_set)
        .permit(reviews_attributes: %i[action comment],
          conditions_attributes: %i[_destroy id standard title text reason])
        .to_h
        .deep_merge(
          reviews_attributes: {
            reviewed_at: Time.current,
            reviewer: current_user,
            status: status,
            review_status: :review_complete,
            id: @pre_commencement_condition_set&.current_review&.id
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
      params.dig(:pre_commencement_condition_set, :reviews_attributes, :action) == "rejected"
    end
  end
end
