# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  include ActionView::Helpers::SanitizeHelper

  before_action :set_planning_application, except: %i[new create index]

  before_action :ensure_user_is_reviewer_checking_assessment, only: %i[edit_public_comment]

  before_action :ensure_no_open_post_validation_requests, only: %i[submit]

  before_action :ensure_draft_recommendation_complete, only: :update

  before_action :check_filter_params, only: :index

  rescue_from PlanningApplication::WithdrawRecommendationError do |_exception|
    redirect_failed_withdraw_recommendation
  end

  rescue_from PlanningApplication::SubmitRecommendationError do |_exception|
    redirect_failed_submit_recommendation
  end

  rescue_from PlanningApplicationCreationService::CreateError do |exception|
    redirect_failed_clone_planning_application(exception)
  end

  def index
    @planning_applications = if helpers.exclude_others? && current_user.assessor?
                               planning_applications_scope.for_user_and_null_users(current_user.id)
                             else
                               planning_applications_scope
                             end

    @search_filter = if params[:planning_application_search_filter].present?
                       PlanningApplicationSearchFilter.new(
                         planning_application_search_filter_params
                       )
                     else
                       PlanningApplicationSearchFilter.new
                     end
  end

  def show; end

  def new
    @planning_application = PlanningApplication.new
  end

  def edit; end

  def create
    @planning_application = PlanningApplication.new(planning_application_params)
    @planning_application.assign_attributes(local_authority: current_local_authority)

    if @planning_application.save
      @planning_application.send_receipt_notice_mail

      redirect_to planning_application_documents_path(@planning_application), notice: t(".success")
    else
      render :new
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
            redirect_to planning_application_other_change_validation_request_path(
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
    @planning_application.default_validated_at
  end

  def validate
    if validation_date_fields_invalid?
      @planning_application.errors.add(:planning_application, "Please enter a valid date")
    elsif @planning_application.open_validation_requests?
      @planning_application.errors.add(:planning_application,
                                       "Planning application cannot be validated if open validation requests exist.")
    elsif @planning_application.invalid_documents.present?
      @planning_application.errors.add(
        :planning_application,
        "This application has an invalid document. You cannot validate an application with invalid documents."
      )
    elsif @planning_application.boundary_geojson.blank?
      @planning_application.errors.add(
        :base,
        :no_boundary_geojson,
        path: planning_application_sitemap_path(@planning_application)
      )
    end

    if @planning_application.errors.any?
      render "confirm_validation"
    else
      @planning_application.validated_at = date_from_params
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
      @cancelled_validation_requests, @active_validation_requests = validation_requests.partition(&:cancelled?)

      flash.now[:alert] = "Please create at least one validation request before invalidating"
      render "validation_requests/index"
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
    @recommended_date = @planning_application.recommendation.created_at.strftime("%d %b %Y")
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

  def publish; end

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

  def validation_documents
    @documents = @planning_application.documents.active
    @additional_document_validation_requests = @planning_application
                                               .additional_document_validation_requests
                                               .pre_validation
                                               .open_or_pending

    respond_to do |format|
      format.html
    end
  end

  def validate_documents
    respond_to do |format|
      if @planning_application.update(validate_documents_params)
        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application),
                      notice: validate_documents_notice(@planning_application)
        end
      else
        format.html { render :validation_documents }
      end
    end
  end

  def clone
    planning_application = PlanningApplicationCreationService.new(planning_application: @planning_application).call

    respond_to do |format|
      format.html { redirect_to planning_application, notice: "Planning application was successfully cloned." }
    end
  end

  private

  def planning_application_search_filter_params
    params
      .require(:planning_application_search_filter)
      .permit(:query, filter_options: [])
      .merge(planning_applications: @planning_applications, submit: params[:submit])
  end

  def validation_date_fields_invalid?
    validation_date_fields.any?(&:blank?) ||
      validation_date_fields.any? { |field| !field.match(/\A[0-9]*\z/) }
  end

  def planning_applications_scope
    @planning_applications_scope ||= current_local_authority.planning_applications.by_created_at_desc
  end

  def planning_application_params
    permitted_keys = %i[address_1
                        address_2
                        application_type
                        applicant_first_name
                        applicant_last_name
                        applicant_phone
                        applicant_email
                        agent_first_name
                        agent_last_name
                        agent_phone
                        agent_email
                        county
                        constraints
                        description
                        proposal_details
                        payment_reference
                        payment_amount
                        postcode
                        public_comment
                        received_at
                        town
                        uprn
                        work_status]
    params.require(:planning_application).permit permitted_keys
  end

  def determination_date_params
    params.require(:planning_application).permit(:determination_date)
  end

  def validate_documents_params
    params.require(:planning_application).permit(:documents_missing)
  end

  def validation_date_fields
    [params[:planning_application]["validated_at(3i)"],
     params[:planning_application]["validated_at(2i)"],
     params[:planning_application]["validated_at(1i)"]]
  end

  def date_from_params
    Time.zone.parse(
      validation_date_fields.join("-")
    )
  end

  def payment_amount_params
    if params[:planning_application]
      params.require(:planning_application).permit(:payment_amount)
    else
      params.permit(:payment_amount)
    end
  end

  def redirect_failed_withdraw_recommendation
    redirect_to view_recommendation_planning_application_path(@planning_application),
                alert: "Error withdrawing recommendation - please contact support."
  end

  def redirect_failed_submit_recommendation
    redirect_to submit_recommendation_planning_application_path(@planning_application),
                alert: "Error submitting recommendation - please contact support."
  end

  def redirect_failed_clone_planning_application(error)
    redirect_to @planning_application,
                alert: "Error cloning application with message: #{error.message}."
  end

  def redirect_update_url
    case params[:edit_action]&.to_sym
    when :edit_payment_amount
      redirect_to planning_application_fee_items_path(@planning_application, validate_fee: "yes"),
                  notice: "Planning application payment amount was successfully updated."
    when :edit_public_comment
      redirect_to edit_planning_application_recommendations_path(@planning_application),
                  notice: "The information appearing on the decision notice was successfully updated."
    else
      redirect_to(after_update_url, notice: t(".success"))
    end
  end

  def after_update_url
    params.dig(:planning_application, :return_to) || @planning_application
  end

  def validate_documents_notice(planning_application)
    if planning_application.documents_missing?
      "Documents required are marked as invalid"
    else
      "Documents required are marked as valid"
    end
  end

  def ensure_no_open_post_validation_requests
    return unless @planning_application.open_post_validation_requests?

    link = view_context.link_to(
      "review open requests",
      post_validation_requests_planning_application_validation_requests_path(@planning_application)
    )
    flash.now[:error] = sanitize "This application has open non-validation requests. Please
        #{link} and resolve them before submitting to your manager."
    render :submit_recommendation and return
  end

  def ensure_draft_recommendation_complete
    return unless @planning_application.try(:assessment_in_progress?)

    flash.now[:alert] = sanitize "Please save and mark as complete the
        #{view_context.link_to 'draft recommendation',
                               new_planning_application_recommendation_path(@planning_application)}
        before updating application fields."

    render :edit and return
  end

  def check_filter_params
    return unless current_user.reviewer? && params[:planning_application_search_filter] && helpers.exclude_others?

    params[:planning_application_search_filter][:filter_options] = filter_option_params.select do |a|
      PlanningApplication::REVIEWER_FILTER_OPTIONS.include?(a)
    end
  end

  def filter_option_params
    params[:planning_application_search_filter][:filter_options]
  end
end
