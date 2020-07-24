# frozen_string_literal: true

class PlanningApplicationsController < AuthenticationController
  include PlanningApplicationDashboardVariables

  before_action :set_planning_application, only: [ :show, :edit, :update ]
  before_action :set_planning_application_dashboard_variables,
                only: [ :show, :edit, :update ]

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

  # rubocop:disable Metrics/MethodLength
  def update
    status = authorize_user_can_update_status(
      planning_application_params[:status]
    )

    if @planning_application.update_and_timestamp_status(status)
      if status == "determined"
        decision_notice_mail
        flash[:notice] = "Decision Notice sent to applicant"
      end

      redirect_to @planning_application
    else
      render :edit
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def set_planning_application
    @planning_application = authorize(PlanningApplication.find(params[:id]))
  end

  def planning_application_params
    params.require(:planning_application).permit(:status)
  end

  def authorize_user_can_update_status(status)
    if status.present? && unpermitted_status_for_user?(status)
      raise Pundit::NotAuthorizedError
    end

    status
  end

  def unpermitted_status_for_user?(status)
    policy(@planning_application).unpermitted_statuses.include?(status)
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
