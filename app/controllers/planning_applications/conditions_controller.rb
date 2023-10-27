# frozen_string_literal: true

module PlanningApplications
  class ConditionsController < AuthenticationController
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
          if @condition_set.update(condition_params.except(:conditions))
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
      @condition_set = @planning_application.condition_set || @planning_application.create_condition_set!
    end

    def condition_params
      params.require(:condition_set)
        .permit(
          conditions: [],
          conditions_attributes: %i[_destroy id standard title text reason]
        )
    end
  end
end
