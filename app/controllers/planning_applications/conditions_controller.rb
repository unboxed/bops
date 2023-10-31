# frozen_string_literal: true

module PlanningApplications
  class ConditionsController < AuthenticationController
    before_action :set_planning_application
    before_action :set_conditions

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
          if @planning_application.update(condition_params)
            redirect_to planning_application_assessment_tasks_path(@planning_application),
              notice: I18n.t("conditions.update.success")
          else
            render :edit
          end
        end
      end
    end

    private

    def set_conditions
      @conditions = @planning_application.conditions
    end

    def condition_params
      params.require(:planning_application)
        .permit(conditions_attributes: %i[_destroy id standard title text reason])
    end
  end
end
