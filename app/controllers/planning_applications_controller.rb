# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application, only: [ :show, :edit, :assess, :determine, :request_correction, :cancel_confirmation, :cancel ]
  before_action :set_planning_application_dashboard_variables,
                only: [ :show, :edit, :assess, :determine, :request_correction, :cancel_confirmation, :cancel ]

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
    status = authorize_user_can_update_status(
        planning_application_params[:status])
    apply_cancellation(status)
    @planning_application.update!(cancellation_comment: planning_application_params[:cancellation_comment])
    if @planning_application.withdrawn? || @planning_application.returned?
      flash[:notice] = "Application has been cancelled"
    end
    redirect_to @planning_application
  end

  def apply_cancellation(status)
    if status == "withdrawn"
      @planning_application.withdraw!
    elsif status == "returned"
      @planning_application.return!
    end
  end

  private

  def set_planning_application
    @planning_application = authorize(PlanningApplication.find(params[:id]))
  end

  def planning_application_params
    params.require(:planning_application).permit(:status, :cancellation_comment)
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
