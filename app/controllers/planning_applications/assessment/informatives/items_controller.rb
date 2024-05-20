# frozen_string_literal: true

module PlanningApplications
  module Assessment
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
                redirect_to edit_planning_application_assessment_informatives_path(@planning_application), notice: t(".success")
              else
                render :edit
              end
            end
          end
        end

        def destroy
          respond_to do |format|
            format.html do
              if @informative.destroy
                redirect_to edit_planning_application_assessment_informatives_path(@planning_application), notice: t(".success")
              else
                redirect_to edit_planning_application_assessment_informatives_path(@planning_application), notice: t(".failure")
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
          params.require(:informative).permit(:title, :text)
        end
      end
    end
  end
end
