# frozen_string_literal: true

class PlanningApplicationCreationService
  class CreateError < StandardError; end

  def initialize(planning_application: nil, **options)
    if planning_application
      raise CreateError, "Cloning is not permitted in production" unless planning_application.can_clone?

      audit_log = planning_application.audit_log
      raise CreateError, "Planning application can not be cloned as it was not created via PlanX" unless audit_log

      @params = ActionController::Parameters.new(JSON.parse(audit_log))
      @local_authority = planning_application.local_authority
      @api_user = planning_application.api_user
      @send_email = false
    else
      options.each { |k, v| instance_variable_set("@#{k}", v) unless v.nil? }
    end
  end

  def call
    save_planning_application!(build_planning_application)
  end

  private

  attr_reader :local_authority, :params, :api_user

  def build_planning_application
    planning_application = PlanningApplication.new(
      planning_application_params.merge!(
        local_authority_id: local_authority.id,
        boundary_geojson: (params[:boundary_geojson].to_json if params[:boundary_geojson].present?),
        proposal_details: (params[:proposal_details].to_json if params[:proposal_details].present?),
        old_constraints: constraints_array_from_param(params[:constraints]),
        planx_data: (params[:planx_debug_data].to_json if params[:planx_debug_data].present?),
        api_user:,
        audit_log: params.to_json,
        user_role: params[:user_role].presence,
        payment_amount: params[:payment_amount].presence && payment_amount_in_pounds(params[:payment_amount]),
        from_production: params[:from_production].present?,
        application_type: ApplicationType.find_by(name: params[:application_type])
      )
    )

    planning_application.assign_attributes(site_params) if site_params.present?
    planning_application.assign_attributes(result_params) if result_params.present?

    planning_application
  end

  def save_planning_application!(planning_application)
    PlanningApplication.transaction do
      if planning_application.save!
        if planning_application.from_production?
          PlanningApplicationAnonymisationService.new(planning_application:).call!
        end
        ConstraintsCreationService.new(planning_application:,
                                       constraints_params: params[:constraints]&.to_unsafe_hash).call
        UploadDocumentsJob.perform_now(planning_application:, files: params[:files])
        CreateImmunityDetailsJob.perform_now(planning_application:) if possibly_immune?(planning_application)
      end
    end

    planning_application.send_receipt_notice_mail unless skip_email?

    planning_application
  rescue Api::V1::Errors::WrongFileTypeError, Api::V1::Errors::GetFileError, ActiveRecord::RecordInvalid,
         ArgumentError, NoMethodError => e
    raise CreateError, e.message
  end

  def planning_application_params
    check_for_prior_approval
    check_for_planning_permission

    permitted_keys = [:application_type,
                      :description,
                      :applicant_first_name,
                      :applicant_last_name,
                      :applicant_phone,
                      :applicant_email,
                      :agent_first_name,
                      :agent_last_name,
                      :agent_phone,
                      :agent_email,
                      :user_role,
                      :proposal_details,
                      :files,
                      :payment_reference,
                      :work_status,
                      :planx_debug_data,
                      :from_production,
                      { feedback: %i[result find_property planning_constraints] }]

    params.permit permitted_keys
  end

  def constraints_array_from_param(constraints_params)
    if constraints_params.present?
      constraints_params.to_unsafe_hash.filter_map do |key, value|
        key if value
      end
    else
      []
    end
  end

  def site_params
    return unless params[:site]

    { uprn: params[:site][:uprn],
      address_1: params[:site][:address_1], # rubocop:disable Naming/VariableNumber
      address_2: params[:site][:address_2], # rubocop:disable Naming/VariableNumber
      town: params[:site][:town],
      postcode: params[:site][:postcode],
      lonlat: lonlat(params[:site][:longitude], params[:site][:latitude]) }
  end

  def result_params
    return unless params[:result]

    { result_flag: params[:result][:flag],
      result_heading: params[:result][:heading],
      result_description: params[:result][:description],
      result_override: params[:result][:override] }
  end

  def payment_amount_in_pounds(amount)
    amount.to_f / 100
  end

  def possibly_immune?(planning_application)
    planning_application.immune_proposal_details.count > 1
  end

  def check_for_prior_approval
    return unless params[:application_type] == "Apply for prior approval"
    raise CreateError, "BoPS does not accept this Prior Approval type" unless permitted_prior_approval_type?

    params[:application_type] = "prior_approval"
  end

  def check_for_planning_permission
    params[:application_type] = "planning_permission" if params[:application_type] == "Apply for planning permission"
  end

  def permitted_prior_approval_type?
    params[:planx_debug_data][:passport][:data][:"application.type"] == ["pa.part1.classA"]
  end

  def skip_email?
    params[:send_email] == "false" || @send_email == false
  end

  def lonlat(longitude, latitude)
    return unless longitude.present? && latitude.present?

    "POINT(#{longitude} #{latitude})"
  end
end
