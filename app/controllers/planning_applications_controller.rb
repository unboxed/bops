# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  before_action :set_planning_application, except: %i[new create index]
  before_action :build_planning_application, only: %i[new create]
  before_action :ensure_draft_recommendation_complete, only: :update

  before_action :redirect_to_reference_url, only: %i[show edit]

  def index
    @show_section_navigation = true
    @search ||= PlanningApplicationSearch.new(params)

    respond_to do |format|
      format.html
    end
  end

  def show
    @show_header_bar = false
    respond_to do |format|
      format.html
    end
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def create
    @planning_application.attributes = planning_application_params

    respond_to do |format|
      if @planning_application.save
        @planning_application.mark_accepted!
        @planning_application.send_receipt_notice_mail

        format.html { redirect_to planning_application_documents_path(@planning_application), notice: t(".success") }
      else
        format.html { render :new }
      end
    end
  end

  def update
    respond_to do |format|
      if @planning_application.update(planning_application_params)
        format.html { redirect_update_url }
      else
        case params[:edit_action]&.to_sym
        when :edit_payment_amount
          format.html do
            redirect_to planning_application_validation_other_change_validation_request_path(
              @planning_application, OtherChangeValidationRequest.find(params[:other_change_validation_request_id])
            ), alert: @planning_application.errors.messages[:payment_amount].join(", ")
          end
        else
          format.html { render :edit }
        end
      end
    end
  end

  def decision_notice
    respond_to do |format|
      format.html
    end
  end

  def supply_documents
    @documents = @planning_application.documents.active

    respond_to do |format|
      format.html
    end
  end

  private

  def build_planning_application
    @planning_application = current_local_authority.planning_applications.new
    @planning_application.case_record = CaseRecord.new(local_authority: current_local_authority)

    @planning_application
  end

  def planning_application_params
    # rubocop:disable Naming/VariableNumber
    permitted_keys = %i[address_1
      address_2
      application_type
      application_type_id
      applicant_first_name
      applicant_last_name
      applicant_phone
      applicant_email
      agent_first_name
      agent_last_name
      agent_phone
      agent_email
      county
      constraints_proposed
      description
      proposal_details
      payment_reference
      payment_amount
      valid_fee
      postcode
      public_comment
      received_at
      town
      uprn
      longitude
      latitude
      make_public]
    # rubocop:enable Naming/VariableNumber

    params.require(:planning_application).permit(*permitted_keys)
  end

  def determination_date_params
    params.require(:planning_application).permit(:determination_date)
  end

  def redirect_update_url
    case params[:edit_action]&.to_sym
    when :edit_payment_amount
      redirect_to planning_application_validation_tasks_path(@planning_application),
        notice: t(".edit_payment_amount")
    else
      redirect_to(after_update_url, notice: t(".success"))
    end
  end

  def after_update_url
    params.dig(:planning_application, :return_to) || @planning_application
  end

  def ensure_draft_recommendation_complete
    return unless @planning_application.try(:assessment_in_progress?)

    flash.now[:alert] = t(".save_and_mark_complete_html", href: new_planning_application_assessment_recommendation_path(@planning_application))
    render :edit and return
  end
end
