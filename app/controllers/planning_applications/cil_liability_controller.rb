# frozen_string_literal: true

module PlanningApplications
  class CilLiabilityController < ApplicationController
    include PlanningApplicationAssessable
    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      if @planning_application.update(cil_liability_params)
        redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
      else
        render :edit
      end
    end

    private

    def cil_liability_params
      params.require(:planning_application).permit([:cil_liable])
    end
  end
end
