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
    when "description_change"
      redirect_to new_planning_application_description_change_validation_request_path
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

  def set_planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def send_validation_request_email(request)
    PlanningApplicationMailer.validation_request_mail(
      @planning_application,
      request
    ).deliver_now
  end

  def email_and_timestamp(request)
    send_validation_request_email(request)

    request.mark_as_sent!
  end
end
