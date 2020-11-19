# frozen_string_literal: true

class Api::V1::PlanningApplicationsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_cors_headers, only: %i[index create], if: :json_request?

  def index
    @planning_applications = PlanningApplication.determined

    respond_to(:json)
  end

  def create
    @planning_application = PlanningApplication.create(full_planning_application_params)
    if @planning_application.save!
      render json: {"message": "Application created: id was #{@planning_application.reference}"}, status: 200
    else
      render error: { error: "Unable to create planning application" }, status: 400
    end

    respond_to(:json)
  end

  private

  def planning_application_params
    permitted_keys = [:application_type,
                      :description,
                      :ward,
                      :site_id]

    params.require(:planning_application).permit permitted_keys
  end

  def full_planning_application_params
    planning_application_params.merge!({ agent_first_name: params[:agent][:first_name],
                                         agent_last_name: params[:agent][:last_name],
                                         agent_email: params[:agent][:email],
                                         agent_phone: params[:agent][:phone],
                                         applicant_first_name: params[:applicant][:first_name],
                                         applicant_last_name: params[:applicant][:last_name],
                                         applicant_email: params[:applicant][:email],
                                         applicant_phone: params[:applicant][:phone],
                                         questions: params[:flow].to_json,
                                         audit_log: params.to_json
                                       })
  end
end
