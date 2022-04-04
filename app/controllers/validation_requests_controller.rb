# frozen_string_literal: true

class ValidationRequestsController < AuthenticationController
  before_action :set_planning_application

  def index
    validation_requests = @planning_application.validation_requests
    @cancelled_validation_requests, @active_validation_requests = validation_requests.partition(&:cancelled?)
  end

  private

  def send_validation_request_email(request)
    PlanningApplicationMailer.validation_request_mail(
      @planning_application,
      request
    ).deliver_now
  end

  def send_description_request_email(request)
    PlanningApplicationMailer.description_change_mail(
      @planning_application,
      request
    ).deliver_now
  end

  def email_and_timestamp(request)
    if request.is_a?(DescriptionChangeValidationRequest)
      send_description_request_email(request)
    else
      send_validation_request_email(request)
    end

    request.mark_as_sent!
  end

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
end
