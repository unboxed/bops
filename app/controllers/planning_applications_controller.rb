# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application, only: [ :show, :edit, :assess, :determine, :request_correction,
                                                   :validate_documents, :cancel_confirmation, :cancel ]
  before_action :set_planning_application_dashboard_variables,
                only: [ :show, :edit, :assess, :determine, :request_correction,
                        :validate_documents, :cancel_confirmation, :cancel ]

  rescue_from Notifications::Client::NotFoundError,
    with: :decision_notice_mail_error

  def index
    if helpers.exclude_others? && current_user.assessor?
      @planning_applications = policy_scope(
        PlanningApplication.where(user_id: current_user.id).or(
          PlanningApplication.where(user_id: nil)))
    else
      @planning_applications = policy_scope(PlanningApplication.all)
    end
  end

  def show
  end

  def edit
  end

  def start
    @planning_application.start!

    redirect_to @planning_application
  end

  def return
    @planning_application.return!

    redirect_to @planning_application
  end

  def invalidate
    @planning_application.invalidate!

    redirect_to @planning_application
  end

  def assess
    @planning_application.assess!

    redirect_to @planning_application
  end

  def determine
    @planning_application.determine!

    decision_notice_mail
    flash[:notice] = "Decision Notice sent to applicant"

    redirect_to @planning_application
  end

  def request_correction
    @planning_application.request_correction!

    redirect_to @planning_application
  end

  def withdraw
    @planning_application.withdraw!

    redirect_to @planning_application
  end

  def cancel_confirmation
    render :cancel_confirmation
  end

  def cancel
    status = authorize_user_can_update_status(params[:planning_application][:status])
    apply_cancellation(status)
    flash[:notice] = "Application has been cancelled"
    redirect_to @planning_application
  end

  def apply_cancellation(status)
    if status == "withdrawn"
      @planning_application.withdraw!(:withdrawn, params[:planning_application][:cancellation_comment])
    elsif status == "returned"
      @planning_application.return!(:returned, params[:planning_application][:cancellation_comment])
    end
  end

  # rubocop: disable Metrics/MethodLength
  def validate_documents
    status = authorize_user_can_update_status(params[:planning_application][:status])
    apply_validation(status)
    if @planning_application.in_assessment?
      flash[:notice] = "Application is ready for assessment"
      redirect_to @planning_application
    elsif @planning_application.invalidated?
      flash[:notice] = "Application has been invalidated"
      redirect_to @planning_application
    else
      render template: "documents/index", planning_application: @planning_application,
             documents: @planning_application.documents
    end
  end
  # rubocop: enable Metrics/MethodLength

  def apply_validation(status)
    if status == "invalidated"
      @planning_application.invalidate!
    elsif status == "in_assessment"
      update_validation_and_start
    else
      @planning_application.errors.add(:planning_application, "Please choose Yes or No")
    end
  end

  def update_validation_and_start
    valid_at = date_string_from_params(params[:planning_application][:'documents_validated_at(3i)'],
                                        params[:planning_application][:'documents_validated_at(2i)'],
                                        params[:planning_application]["documents_validated_at(1i)"])
    @planning_application.update!(documents_validated_at: valid_at)
    if @planning_application.save
      @planning_application.start!
    else
      render template: "documents/index", planning_application: @planning_application,
           documents: @planning_application.documents
    end
  end

  def date_string_from_params(year, month, day)
    valid_date = [year, month, day].join("-")
    if valid_date.match?(/\d{2}-\d{2}-\d{4}/)
      valid_date
    else
      @planning_application.errors.add(:planning_application, "Please enter a valid date")
    end
  end

  private

  def set_planning_application
    @planning_application = authorize(PlanningApplication.find(params[:id]))
  end

  def authorize_user_can_update_status(status)
    if status.present? && unpermitted_status_for_user?(status)
      raise Pundit::NotAuthorizedError
    end

    status
  end

  def unpermitted_status_for_user?(status)
    status == :awaiting_determination if current_user.assessor?
  end

  def decision_notice_mail
    PlanningApplicationMailer.decision_notice_mail(
      @planning_application
    ).deliver_now
  end

  def decision_notice_mail_error
    flash[:notice] =
      "The Decision Notice cannot be sent. Please try again later."
    render :edit
  end
end
