# frozen_string_literal: true

module PlanningApplications
  class ConditionsController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_new_conditions, only: :new
    before_action :set_conditions, only: :edit

    def show; end

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
        set_new_conditions
        render :new
      end
    end

    def update
      if update_conditions
        respond_to do |format|
          format.html do
            redirect_to(planning_application_assessment_tasks_path(@planning_application),
                        notice: I18n.t("conditions.update.success"))
          end
        end
      else
        set_conditions
        render :edit
      end
    end

    private

    def update_conditions
      ActiveRecord::Base.transaction do
        @planning_application.update(condition_params) &&
          @planning_application.conditions.each do |condition|
            condition.destroy if irrelevant_conditions.include? condition.id
          end
      end
    end

    def condition_params
      params.require(:planning_application)
            .permit(conditions_attributes: %i[text reason id])
    end

    def set_new_conditions
      @conditions = t("conditions_list").map do |_key, value|
        Condition.new(text: value[:condition], reason: value[:reason], title: value[:title])
      end
    end

    def set_conditions
      new_conditions = t("conditions_list").map do |_key, value|
        next if @planning_application.conditions.pluck(:text).include? value[:condition]

        Condition.new(text: value[:condition], reason: value[:reason])
      end.compact_blank

      @conditions = @planning_application.conditions + new_conditions
    end

    def irrelevant_conditions
      conditions = []
      params[:planning_application][:conditions_attributes].each do |_key, value|
        next if value[:conditions] == ["true"]

        conditions << value[:id].to_i
      end

      conditions
    end
  end
end
