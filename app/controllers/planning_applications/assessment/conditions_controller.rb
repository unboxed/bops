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
          .to_h.merge(reviews_attributes: [status:, id: (@condition_set&.current_review&.id if !mark_as_complete?)])
      end

      def status
        if mark_as_complete?
          if @condition_set.current_review.present? && @condition_set.current_review.status == "to_be_reviewed"
            "updated"
          else
            "complete"
          end
        else
          "in_progress"
        end
      end
    end
  end
end
