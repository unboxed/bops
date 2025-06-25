# frozen_string_literal: true

module PlanningApplications
  module Review
    module PreCommencementConditions
      class ItemsController < BaseController
        before_action :set_condition_set
        before_action :set_condition

        def edit
          respond_to do |format|
            format.html
          end
        end

        def update
          respond_to do |format|
            format.html do
              if @condition.update(condition_params)
                redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-pre-commencement-conditions"), notice: t(".success")
              else
                render :edit
              end
            end
          end
        end

        private

        def set_condition_set
          @condition_set = @planning_application.pre_commencement_condition_set
        end

        def set_condition
          @condition = @condition_set.conditions.find(params[:id])
        end

        def condition_params
          params.require(:condition).permit(:title, :text, :reason).merge(reviewer_edited: true)
        end
      end
    end
  end
end
