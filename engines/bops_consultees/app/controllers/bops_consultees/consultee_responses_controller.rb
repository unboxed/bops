# frozen_string_literal: true

module BopsConsultees
  class ConsulteeResponsesController < ApplicationController
    before_action :set_planning_application
    before_action :set_consultee
    before_action :set_consultee_response

    def update
      if @consultee_response.update(consultee_response_params)
        redirect_to planning_application_path(@planning_application, sgid: params[:sgid]),
          notice: "Your response has been updated."
      else
        render "bops_consultees/planning_applications/show", status: :unprocessable_entity
      end
    end

    private

    def planning_applications_scope
      @current_local_authority.planning_applications
    end

    def set_planning_application
      planning_application = planning_applications_scope.find_by!(reference:)
      @planning_application = PlanningApplicationPresenter.new(view_context, planning_application)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def set_consultee
      expired_resource = BopsCore::SgidAuthenticationService.new(params[:sgid]).expired_resource
      @consultee = @planning_application.consultation.consultees.find(expired_resource.id)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def set_consultee_response
      @consultee_response = @consultee.responses.first_or_initialize
    end

    def consultee_response_params
      params.require(:consultee_response).permit(:summary_tag, :response)
    end

    def reference
      params[:planning_application_reference]
    end

    def render_expired
      render "bops_consultees/dashboards/show"
    end
  end
end
