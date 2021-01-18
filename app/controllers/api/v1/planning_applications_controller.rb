# frozen_string_literal: true

class Api::V1::PlanningApplicationsController < Api::V1::ApplicationController
  before_action :set_cors_headers, only: %i[index show create], if: :json_request?
  skip_before_action :authenticate, only: %i[index show decision_notice]
  skip_before_action :set_default_format, only: %i[decision_notice]

  def index
    @planning_applications = current_local_authority.planning_applications.all

    respond_to(:json)
  end

  def show
    @planning_application = current_local_authority.planning_applications.where(id: params[:id]).first
    if @planning_application
      respond_to(:json)
    else
      send_not_found_response
    end
  end

  def decision_notice
    @planning_application = current_local_authority.planning_applications.where(id: params[:id]).first
    @blank_layout = true
  end

  def create
    site_id = create_site
    @planning_application = PlanningApplication.new(
      full_planning_params.merge!(site_id: site_id, local_authority_id: @current_local_authority.id),
    )
    if @planning_application.valid? && @planning_application.save!
      attach_question_flow(@planning_application.questions)
      upload_documents(params[:files])
      send_success_response
    else
      send_failed_response
    end
  end

  def attach_question_flow(questions)
    evaluation = @planning_application.create_policy_evaluation
    if questions.blank?
      evaluation
    else
      pcb = Ripa::PolicyConsiderationBuilder.new(questions)
      questions = pcb.import
      evaluation.policy_considerations << questions
    end
  end

  def upload_documents(document_params)
    unless document_params.nil?
      document_params.each do |param|
        document = @planning_application.documents.create!(tags: Array(param[:tags]))
        document.file.attach(io: URI.parse(param[:filename]).open, filename: new_filename(param[:filename]).to_s)
      end
    end
  end

  def new_filename(name)
    name.split("/")[-1]
  end

  def send_success_response
    render json: { "id": @planning_application.reference.to_s,
                   "message": "Application created" }, status: :ok
  end

  def send_failed_response
    render json: { "message": "Unable to create application" },
           status: :bad_request
  end

  def send_not_found_response
    render json: { "message": "Unable to find record" },
           status: :not_found
  end

  def create_site
    if site_params
      site = Site.create_with(site_params)
          .find_or_create_by!(uprn: site_params[:uprn])
      site.id
    end
  end

private

  def planning_application_params
    permitted_keys = %i[application_type
                        description
                        ward
                        site_id
                        applicant_first_name
                        applicant_last_name
                        applicant_phone
                        applicant_email
                        agent_first_name
                        agent_last_name
                        agent_phone
                        agent_email
                        questions
                        files
                        payment_reference
                        work_status]
    params.permit permitted_keys
  end

  def site_params
    if params[:site]
      { uprn: params[:site][:uprn],
        address_1: params[:site][:address_1],
        town: params[:site][:town],
        postcode: params[:site][:postcode] }
    end
  end

  def full_planning_params
    planning_application_params.merge!({
      questions: (params[:questions].to_json if params[:questions].present?),
      constraints: (params[:constraints].to_json if params[:constraints].present?),
      audit_log: params.to_json,
    })
  end
end
