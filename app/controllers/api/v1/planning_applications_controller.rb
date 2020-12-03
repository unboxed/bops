# frozen_string_literal: true

class Api::V1::PlanningApplicationsController < Api::V1::ApplicationController
  before_action :set_cors_headers, only: %i[index create], if: :json_request?
  skip_before_action :authenticate, only: [:index]

  def index
    @planning_applications = PlanningApplication.determined

    respond_to(:json)
  end

  def create
    site_id = create_site
    full_planning_application(site_id, @current_local_authority.id)
    if @planning_application.valid? && @planning_application.save!
      attach_question_flow(@planning_application.questions)
      send_success_response
    else
      send_failed_response
    end
    respond_to(:json)
  end

  def full_planning_application(site_id, council_id)
    @planning_application = PlanningApplication.create(
      full_planning_params.merge!(site_id: site_id, local_authority_id: council_id)
    )
  end

  def attach_question_flow(questions)
    evaluation = @planning_application.create_policy_evaluation
    pcb = Ripa::PolicyConsiderationBuilder.new(questions)
    if questions.empty?
      evaluation
    else
      questions = pcb.import
      evaluation.policy_considerations << questions
    end
  end

  def send_success_response
    render json: { "id": "#{@planning_application.reference}",
                   "message": "Application created" }, status: 200
  end

  def send_failed_response
    render json: { "message": "Unable to create application" },
                   status: 400
  end

  def create_site
    if site_params
      site = Site.create_with(site_params).
          find_or_create_by!(uprn: site_params[:uprn])
      site.id
    else
    end
  end

  private

  def planning_application_params
    permitted_keys = [:application_type, :description, :ward, :site_id,
                      :applicant_first_name, :applicant_last_name,
                      :applicant_phone, :applicant_email,
                      :agent_first_name, :agent_last_name,
                      :agent_phone, :agent_email, :questions]

    params.permit permitted_keys
  end

  def site_params
    if params[:site]
      { uprn: params[:site][:uprn],
        address_1: params[:site][:address_1],
        town: params[:site][:town],
        postcode: params[:site][:postcode]
      }
    end
  end

  def full_planning_params
    planning_application_params.merge!({
                                         questions: params[:questions].to_json,
                                         constraints: params[:constraints].to_json,
                                         audit_log: params.to_json
                                       })
  end
end
