# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class ConditionsController < BaseController
      before_action :set_condition_set

      def index
        @conditions = @condition_set.conditions
        @condition = @conditions.new

        respond_to do |format|
          format.html
        end
      end

      def edit
        @condition = @condition_set.conditions.find(Integer(params[:id]))

        respond_to do |format|
          format.html
        end
      end

      def create
        @condition = @condition_set.conditions.new
        if @condition.update(condition_params)
          redirect_to planning_application_assessment_conditions_path(@planning_application),
            notice: I18n.t("conditions.update.success")
        else
          render :edit
        end
      end

      def update
        respond_to do |format|
          format.html do
            @condition = @condition_set.conditions.find(condition_id)
            if @condition.update(condition_params)
              redirect_to planning_application_assessment_conditions_path(@planning_application),
                notice: I18n.t("conditions.update.success")
            else
              render :edit
            end
          end
        end
      end

      def destroy
        @condition = @condition_set.conditions.find(Integer(params[:id]))

        respond_to do |format|
          format.html do
            if @condition.destroy
              redirect_to planning_application_assessment_conditions_path(@planning_application),
                notice: I18n.t("conditions.destroy.success")
            else
              redirect_to planning_application_assessment_conditions_path(@planning_application),
                notice: I18n.t("conditions.destroy.failure")
            end
          end
        end
      end

      def mark_as_complete
        current_review = @condition_set.current_review
        if current_review.status == "to_be_reviewed"
          @condition_set.reviews.create!(status: "updated")
          redirect_to planning_application_assessment_tasks_path(@planning_application),
            notice: I18n.t("conditions.update.success")
        elsif current_review.update(status:)
          redirect_to planning_application_assessment_tasks_path(@planning_application),
            notice: I18n.t("conditions.update.success")
        else
          render :index
        end
      end

      private

      def condition_id
        Integer(condition_params[:id])
      end

      def set_condition_set
        @condition_set = @planning_application.condition_set
      end

      def condition_params
        params.require(:condition).permit(%i[id title text reason]).to_h.merge(standard: false)
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
