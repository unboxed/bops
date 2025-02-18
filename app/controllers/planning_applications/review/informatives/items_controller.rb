# frozen_string_literal: true

module PlanningApplications
  module Review
    module Informatives
      class ItemsController < BaseController
        before_action :set_informative_set
        before_action :set_informative

        def edit
          respond_to do |format|
            format.html
          end
        end

        def update
          respond_to do |format|
            format.html do
              if @informative.update(informative_params)
                redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-informatives"), notice: t(".success")
              else
                render :edit
              end
            end
          end
        end

        private

        def set_informative_set
          @informative_set = @planning_application.informative_set
        end

        def set_informative
          @informative = @informative_set.informatives.find(params[:id])
        end

        def informative_params
          params.require(:informative).permit(:title, :text).merge(reviewer_edited: true)
        end
      end
    end
  end
end
