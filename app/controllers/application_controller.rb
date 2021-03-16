# frozen_string_literal: true

class ApplicationController < ActionController::Base
  rescue_from Notifications::Client::NotFoundError, with: :decision_notice_mail_error
  rescue_from Notifications::Client::ServerError, with: :validation_notice_request_error
  rescue_from Notifications::Client::RequestError, with: :validation_notice_request_error
  rescue_from Notifications::Client::ClientError, with: :validation_notice_request_error
  rescue_from Notifications::Client::BadRequestError, with: :validation_notice_request_error

  before_action :find_current_local_authority_from_subdomain
  before_action :prevent_caching

  attr_reader :current_local_authority

  helper_method :current_local_authority

  def audit(activity_type, audit_comment = nil, activity_information = nil)
    Audit.create!(
      planning_application_id: @planning_application.id,
      user: current_user,
      audit_comment: audit_comment,
      activity_information: activity_information,
      activity_type: activity_type,
    )
  end

private

  def find_current_local_authority_from_subdomain
    unless @current_local_authority ||= LocalAuthority.find_by(subdomain: request.subdomains.first)
      render plain: "No Local Authority Found", status: :not_found
    end
  end

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = 100.years.ago
  end

  def disable_flash_header
    @disable_flash_header = true
  end

  def decision_notice_mail_error
    flash[:error] = "The email cannot be sent. Please try again later."
    render "documents/index"
  end

  def validation_notice_request_error(exception)
    flash[:error] = "#{exception}. Please modify details or try again later."
    Appsignal.send_error(exception)
    render "documents/index"
  end
end
