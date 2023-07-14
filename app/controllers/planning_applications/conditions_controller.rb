# frozen_string_literal: true

module PlanningApplications
  class ConditionsController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_conditions, only: :new

    def new; end

    def edit; end

    def create
      if @planning_application.update(condition_params)
        respond_to do |format|
          format.html do
            redirect_to(planning_application_assessment_tasks_path(@planning_application),
                        notice: I18n.t("conditions.create.success"))
          end
        end
      else
        set_conditions
        render :new
      end
    end

    private

    def condition_params
      params.require(:planning_application)
            .permit(conditions_attributes: %i[text reason])
    end

    def set_conditions
      @conditions = t("conditions").map do |condition|
        Condition.new(text: condition.second[:condition], reason: condition.second[:reason])
      end
    end
  end
end
