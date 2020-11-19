# frozen_string_literal: true

class Api::V1::PlanningApplicationsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_cors_headers, only: %i[index create], if: :json_request?

  def index
    @planning_applications = PlanningApplication.determined

    respond_to(:json)
  end

  def create
    @plan_app = PlanningApplication.create(full_planning_application_params)
    if @plan_app.save!
      @plan_app.create_policy_evaluation
      render json: { "id": "#{@plan_app.reference}",
                    "message": "Application created" }, status: 200
    else
      render error: { error: "Unable to create application" }, status: 400
    end
    respond_to(:json)
  end

  private

  def planning_application_params
    permitted_keys = [:application_type, :description, :ward, :site_id,
                      :applicant_first_name, :applicant_last_name,
                      :applicant_phone, :applicant_email,
                      :agent_first_name, :agent_last_name,
                      :agent_phone, :agent_email]

    params.require(:planning_application).permit permitted_keys
  end

  def full_planning_application_params
    planning_application_params.merge!({
                                         questions: params[:flow].to_json,
                                         audit_log: params.to_json
                                       })
  end
end
