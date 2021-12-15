# frozen_string_literal: true

class ValidationRequestsController < ApplicationController
  before_action :set_planning_application

  def index
    validation_requests = @planning_application.validation_requests
    @cancelled_validation_requests, @active_validation_requests = validation_requests.partition(&:cancelled?)
  end

  def new; end

  def create
    case params[:validation_request]
    when "replacement_document"
      redirect_to new_planning_application_replacement_document_validation_request_path
    when "create_document"
      redirect_to new_planning_application_additional_document_validation_request_path
    when "other_validation"
      redirect_to new_planning_application_other_change_validation_request_path
    when "red_line_boundary"
      redirect_to new_planning_application_red_line_boundary_change_validation_request_path
    else
      flash.now[:error] = "You must select a validation request type to proceed."
      render "new"
    end
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

    event = request.planning_application.invalidated? ? "sent" : "added"
    audit_request_sent_or_added(request, event)
  end

  def audit_request_sent_or_added(request, event)
    audit("#{request.model_name.param_key}_#{event}",
          "#{request.audit_item}",
          "#{request.sequence}")
  end
end
