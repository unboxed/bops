# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConditionsController < AuthenticationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_condition_set
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
            if @condition_set.update(condition_params)
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

      def set_conditions
        @conditions = @condition_set.conditions
      end

      def condition_params
        params.require(:condition_set)
          .permit(
            conditions_attributes: %i[_destroy id standard title text reason]
          )
          .to_h.merge(review_attributes: [status:])
      end

      def status
        mark_as_complete? ? :complete : :in_progress
      end
    end
  end
end
