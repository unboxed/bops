# frozen_string_literal: true

class ValidationRequestsController < AuthenticationController
  include PlanningApplicationAssessable

  rescue_from Notifications::Client::NotFoundError, with: :validation_notice_request_error
  rescue_from Notifications::Client::ServerError, with: :validation_notice_request_error
  rescue_from Notifications::Client::RequestError, with: :validation_notice_request_error
  rescue_from Notifications::Client::ClientError, with: :validation_notice_request_error
  rescue_from Notifications::Client::BadRequestError, with: :validation_notice_request_error
  rescue_from ValidationRequestable::ValidationRequestNotCreatableError, with: :redirect_failed_create_request_error

  before_action :set_planning_application
  before_action :ensure_planning_application_is_validated, only: :post_validation_requests

  def index
    validation_requests = @planning_application.validation_requests
    @cancelled_validation_requests, @active_validation_requests = validation_requests.partition(&:cancelled?)

    respond_to do |format|
      format.html
    end
  end

  def post_validation_requests
    validation_requests = @planning_application.validation_requests(
      post_validation: true,
      include_description_change_validation_requests: true
    )

    @cancelled_validation_requests, @active_validation_requests = validation_requests.partition(&:cancelled?)

    respond_to do |format|
      format.html { render "index" }
    end
  end

  private

  def ensure_planning_application_not_validated
    render plain: "forbidden", status: :forbidden and return unless @planning_application.can_validate?
  end

  def ensure_no_open_or_pending_fee_item_validation_request
    return unless @planning_application.fee_item_validation_requests.open_or_pending.any?

    render plain: "forbidden", status: :forbidden
  end

  def ensure_no_open_or_pending_red_line_boundary_validation_request
    return unless @planning_application.red_line_boundary_change_validation_requests.open_or_pending.any?

    render plain: "forbidden", status: :forbidden
  end

  def ensure_planning_application_not_invalidated
    return if @planning_application.not_started?

    render plain: "forbidden", status: :forbidden
  end

  def validation_notice_request_error(exception)
    flash[:alert] = "Notify was unable to send applicant email. Please contact the applicant directly."

    Appsignal.send_error(exception)
    render "planning_applications/show"
  end

  def ensure_planning_application_is_not_closed_or_cancelled
    return unless @planning_application.closed_or_cancelled?

    render plain: "forbidden", status: :forbidden
  end

  def create_request_redirect_url
    if @planning_application.validated?
      @planning_application
    else
      planning_application_validation_tasks_path(@planning_application)
    end
  end

  def redirect_failed_create_request_error(error)
    redirect_to @planning_application, alert: error.message
  end
end
