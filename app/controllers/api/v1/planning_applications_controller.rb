# frozen_string_literal: true

class Api::V1::PlanningApplicationsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_cors_headers, only: %i[index create], if: :json_request?

  def index
    @planning_applications = PlanningApplication.determined

    respond_to(:json)
  end

  def create
    site_id = create_site
    @planning_application = PlanningApplication.create(
      full_planning_params.merge!(site_id: site_id)
                                                      )
    send_response
    respond_to(:json)
  end

  def send_response
    if @planning_application.save!
      @planning_application.create_policy_evaluation
      render json: { "id": "#{@planning_application.reference}",
                     "message": "Application created" }, status: 200
    else
      render error: { error: "Unable to create application" }, status: 400
    end
  end

  def create_site
    site = Site.create_with(site_params).
        find_or_create_by!(uprn: site_params[:uprn])
    site.id
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

  def site_params
    { uprn: params[:site][:uprn],
      address_1: params[:site][:address_1],
      town: params[:site][:town],
      postcode: params[:site][:postcode]
    }
  end

  def full_planning_params
    planning_application_params.merge!({
                                         questions: params[:flow].to_json,
                                         audit_log: params.to_json
                                       })
  end
end
