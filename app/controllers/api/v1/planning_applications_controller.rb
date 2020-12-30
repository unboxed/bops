# frozen_string_literal: true

class Api::V1::PlanningApplicationsController < Api::V1::ApplicationController
  before_action :set_cors_headers, only: %i[index show create], if: :json_request?
  skip_before_action :authenticate, only: %i[index show]

  def index
    @planning_applications = PlanningApplication.all

    respond_to(:json)
  end

  def show
    @planning_application = PlanningApplication.where(id: params[:id]).first
    if @planning_application
      respond_to(:json)
    else
      send_not_found_response
    end
  end

  def create
    site_id = create_site
    full_planning_application(site_id, @current_local_authority.id)
    if @planning_application.valid? && @planning_application.save!
      attach_question_flow(@planning_application.questions)
      upload_documents(params[:plans])
      send_success_response
    else
      send_failed_response
    end
  end

  def full_planning_application(site_id, council_id)
    @planning_application = PlanningApplication.create(
      full_planning_params.merge!(site_id: site_id, local_authority_id: council_id)
    )
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
        document = @planning_application.documents.create(tags: Array(param[:tags]))
        document.plan.attach(io: File.open(open(param[:filename])), filename: "#{new_plan_filename(param[:filename])}")
      end
    end
  end

  def new_plan_filename(name)
    name.split("/")[-1]
  end

  def send_success_response
    render json: { "id": "#{@planning_application.reference}",
                   "message": "Application created" }, status: 200
  end

  def send_failed_response
    render json: { "message": "Unable to create application" },
           status: 400
  end

  def send_not_found_response
    render json: { "message": "Unable to find record" },
           status: 404
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
                      :agent_phone, :agent_email, :questions, :plans,
                      :payment_reference]
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
                                           questions: (params[:questions].to_json if params[:questions].present?),
                                           constraints: (params[:constraints].to_json if params[:constraints].present?),
                                           audit_log: params.to_json
                                       })
  end
end
