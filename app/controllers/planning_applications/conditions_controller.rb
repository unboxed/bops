# frozen_string_literal: true

module PlanningApplications
  class ConditionsController < AuthenticationController
    include CommitMatchable

    before_action :set_planning_application
    before_action :set_new_conditions, only: :new
    before_action :set_conditions, only: :edit

    def show
    end

    def new
    end

    def edit
    end

    def create
      if @planning_application.update(assign_params)
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
        @planning_application.update(assign_params) && destroy_old_conditions
      end
    end

    def condition_params
      params.require(:planning_application)
        .permit(
          conditions_attributes: [:title, :text, :reason, :id, :standard, :new_condition, {conditions: []}]
        )
    end

    def assign_params
      new_params = condition_params
      new_params[:conditions_attributes] = condition_params[:conditions_attributes].select do |_key, value|
        value[:conditions].present? ||
          (value[:standard] == "false" && (value[:text].present? || value[:reason].present?))
      end
      new_params
    end

    def set_new_conditions
      @conditions = t("conditions_list").map do |_key, value|
        construct_condition(value)
      end
    end

    def set_conditions
      new_conditions = t("conditions_list").map do |_key, value|
        next if @planning_application.conditions.pluck(:title).include? value[:title]

        construct_condition(value)
      end.compact_blank

      @conditions = @planning_application.conditions + new_conditions
    end

    def irrelevant_condition_ids
      conditions = []
      params[:planning_application][:conditions_attributes].each do |_key, value|
        next if value[:conditions] == ["true"]

        conditions << value[:id].to_i
      end
      conditions
    end

    def relevant_condition_ids
      conditions = []
      params[:planning_application][:conditions_attributes].each do |_key, value|
        conditions << value[:id].to_i if value[:standard] == "false"
      end
      conditions
    end

    def construct_condition(value)
      Condition.new(text: value[:condition], reason: value[:reason], standard: true, title: value[:title])
    end

    def destroy_old_conditions
      @planning_application.conditions.each do |condition|
        if condition.standard?
          condition.destroy if irrelevant_condition_ids.include?(condition.id)
        else
          condition.destroy unless relevant_condition_ids.include?(condition.id) || condition.id_previously_changed?
        end
      end
    end
  end
end
