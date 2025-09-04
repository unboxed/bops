# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  before_action :set_planning_application, except: %i[new create index]
  before_action :build_planning_application, only: %i[new create]
  before_action :ensure_planning_application_is_publishable, only: %i[make_public]
  before_action :ensure_user_is_reviewer_checking_assessment, only: %i[edit_public_comment]
  before_action :ensure_no_open_post_validation_requests, only: %i[submit]
  before_action :ensure_draft_recommendation_complete, only: :update
  before_action :ensure_site_notice_displayed_at, only: %i[determine]
  before_action :ensure_press_notice_published_at, only: %i[determine]
  before_action :ensure_planning_application_is_not_preapp, only: %i[submit_recommendation view_recommendation]

  before_action :redirect_to_reference_url, only: %i[show edit]

  rescue_from PlanningApplication::WithdrawRecommendationError do |_exception|
    redirect_failed_withdraw_recommendation
  end

  rescue_from PlanningApplication::SubmitRecommendationError do |_exception|
    redirect_failed_submit_recommendation
  end

  def index
    @search ||= PlanningApplicationSearch.new(params)

    respond_to do |format|
      format.html
    end
  end

  def show
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
        when :edit_public_comment
          format.html { render :edit_public_comment }
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

  def confirm_validation
    @planning_application.update(validated_at: @planning_application.valid_from_date)
  end

  def validate
    if @planning_application.validation_requests.pending.any?
      @planning_application.errors.add(:planning_application,
        "Planning application cannot be validated if pending validation requests exist.")
    elsif @planning_application.invalid_documents.present?
      @planning_application.errors.add(
        :planning_application,
        "This application has an invalid document. You cannot validate an application with invalid documents."
      )
    elsif @planning_application.boundary_geojson.blank?
      @planning_application.errors.add(
        :base,
        :no_boundary_geojson,
        path: planning_application_validation_sitemap_path(@planning_application)
      )
    end

    if @planning_application.errors.any?
      render "confirm_validation"
    else
      @planning_application.update!(planning_application_params)
      @planning_application.start!
      @planning_application.send_validation_notice_mail

      redirect_to @planning_application, notice: t(".success")
    end
  end

  def invalidate
    if @planning_application.may_invalidate?
      @planning_application.invalidate!

      @planning_application.send_invalidation_notice_mail

      redirect_to @planning_application, notice: t(".success")
    else
      validation_requests = @planning_application.validation_requests
      @cancelled_validation_requests = validation_requests.where(state: "cancelled")
      @active_validation_requests = validation_requests.where.not(state: "cancelled")

      flash.now[:alert] = t(".failure")
      render "planning_applications/validation/validation_requests/index"
    end
  end

  def edit_public_comment
    respond_to do |format|
      format.html { render :edit_public_comment }
    end
  end

  def submit_recommendation
    respond_to do |format|
      if @planning_application.can_submit_recommendation?
        format.html { render :submit_recommendation }
      else
        format.html { render plain: "Not Found", status: :not_found }
      end
    end
  end

  def view_recommendation
    @assessor_name = @planning_application.recommendation.assessor.name
    @recommended_date = @planning_application.recommendation.created_at.to_date.to_fs
  end

  def withdraw_recommendation
    respond_to do |format|
      if @planning_application.may_withdraw_recommendation?
        @planning_application.withdraw_last_recommendation!

        format.html do
          redirect_to submit_recommendation_planning_application_path(@planning_application),
            notice: t(".success")
        end
      else
        format.html { redirect_failed_withdraw_recommendation }
      end
    end
  end

  def submit
    respond_to do |format|
      if @planning_application.can_submit_recommendation?
        @planning_application.submit_recommendation!

        format.html do
          redirect_to @planning_application, notice: t(".success")
        end
      else
        format.html { redirect_failed_submit_recommendation }
      end
    end
  end

  def publish
    respond_to do |format|
      format.html
    end
  end

  def make_public
    respond_to do |format|
      format.html
    end
  end

  def determine
    respond_to do |format|
      @planning_application.assign_attributes(determination_date_params)

      if @planning_application.valid?
        @planning_application.determine!

        @planning_application.send_decision_notice_mail(request.host)

        format.html do
          redirect_to @planning_application, notice: t(".success")
        end
      else
        format.html { render :publish }
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

  def redirect_failed_withdraw_recommendation
    redirect_to view_recommendation_planning_application_path(@planning_application),
      alert: t("planning_applications.withdraw_recommendation.failure")
  end

  def redirect_failed_submit_recommendation
    redirect_to submit_recommendation_planning_application_path(@planning_application),
      alert: t("planning_applications.submit_recommendation.failure")
  end

  def redirect_update_url
    case params[:edit_action]&.to_sym
    when :edit_payment_amount
      redirect_to planning_application_validation_tasks_path(@planning_application),
        notice: t(".edit_payment_amount")
    when :edit_public_comment
      redirect_to planning_application_review_tasks_path(@planning_application),
        notice: t(".edit_public_comment")
    else
      redirect_to(after_update_url, notice: t(".success"))
    end
  end

  def after_update_url
    params.dig(:planning_application, :return_to) || @planning_application
  end

  def ensure_planning_application_is_publishable
    return if @planning_application.publishable?

    redirect_to planning_application_assessment_tasks_path(@planning_application),
      alert: t(".not_publishable", application_type: @planning_application.application_type.description)
  end

  def ensure_no_open_post_validation_requests
    return if @planning_application.no_open_post_validation_requests_excluding_time_extension?

    flash.now[:alert] = t(".has_open_non_validation_requests_html", href: post_validation_requests_planning_application_validation_validation_requests_path(@planning_application))
    render :submit_recommendation and return
  end

  def ensure_draft_recommendation_complete
    return unless @planning_application.try(:assessment_in_progress?)

    flash.now[:alert] = t(".save_and_mark_complete_html", href: new_planning_application_assessment_recommendation_path(@planning_application))
    render :edit and return
  end

  def ensure_site_notice_displayed_at
    return unless @planning_application.site_notice_needs_displayed_at?

    flash.now[:alert] = t(".confirm_site_notice_displayed_at_html", href: edit_planning_application_site_notice_path(@planning_application, @planning_application.site_notice))
    render :publish and return
  end

  def ensure_press_notice_published_at
    return unless @planning_application.press_notice_needs_published_at?

    flash.now[:alert] = t(".confirm_press_notice_published_at_html", href: planning_application_press_notice_confirmation_path(@planning_application))
    render :publish and return
  end
end
