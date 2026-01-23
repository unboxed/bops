# frozen_string_literal: true

module BopsConsultees
  class ConsulteeResponsesController < ApplicationController
    before_action :set_planning_application
    before_action :set_consultee
    before_action :set_consultee_response

    def create
      @consultee_response.assign_attributes(consultee_response_params.merge(received_at: Time.zone.now))
      if @consultee_response.save
        redirect_to planning_application_path(@planning_application, sgid: params[:sgid]),
          notice: "Your response has been updated."
      else
        render "bops_consultees/planning_applications/show", status: :unprocessable_content
      end
    end

    private

    def set_consultee
      expired_resource = BopsCore::SgidAuthenticationService.new(params[:sgid]).expired_resource
      @consultee = @planning_application.consultation.consultees.find(expired_resource.id)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def set_consultee_response
      @consultee_response = @consultee.responses.new
    end

    def consultee_response_params
      params.require(:consultee_response).permit(:summary_tag, :response, :email, documents: [])
    end

    def render_expired
      render "bops_consultees/planning_applications/index"
    end
  end
end
