# frozen_string_literal: true

module PlanningApplications
  class CilLiabilityController < ApplicationController
    include PlanningApplicationAssessable
    before_action :set_planning_application

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      if @planning_application.update(cil_liability_params)
        redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(".success")
      else
        render :edit
      end
    end

    private

    def planning_application_id
      Integer(params[:planning_application_id])
    end

    def planning_applications_scope
      current_local_authority.planning_applications
    end

    def set_planning_application
      planning_application = planning_applications_scope.find(planning_application_id)

      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    end

    def cil_liability_params
      params.require(:planning_application).permit([:cil_liable])
    end
  end
end
