# frozen_string_literal: true

module PlanningApplications
  class ConditionsController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_new_conditions, only: :new
    before_action :set_conditions, only: :edit

    def new; end

    def show; end

    def edit; end

    def create
      if @planning_application.update(condition_params)
        respond_to do |format|
          format.html do 
            redirect_to(planning_application_assessment_tasks_path(@planning_application),notice: I18n.t("conditions.create.success"))
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
            redirect_to(planning_application_assessment_tasks_path(@planning_application),notice: I18n.t("conditions.update.success"))
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
        .permit(conditions_attributes: [:text, :reason, :id])
    end

    def set_new_conditions
      @conditions = t("conditions").map do |condition|
        Condition.new(text: condition.second[:condition], reason: condition.second[:reason])
      end
    end

    def set_conditions
      new_conditions = t("conditions").map do |condition|
        next if @planning_application.conditions.pluck(:text).include? condition.second[:condition]

        Condition.new(text: condition.second[:condition], reason: condition.second[:reason])
      end.compact_blank

      @conditions = @planning_application.conditions + new_conditions
    end

    def irrelevant_conditions
      conditions = []
      params[:planning_application][:conditions_attributes].each do |key, value|
        next if value[:conditions] == ["true"]

        conditions << value[:id].to_i
      end

      conditions
    end
  end
end
