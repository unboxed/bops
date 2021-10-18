# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Auditable

  rescue_from Notifications::Client::NotFoundError, with: :validation_notice_request_error
  rescue_from Notifications::Client::ServerError, with: :validation_notice_request_error
  rescue_from Notifications::Client::RequestError, with: :validation_notice_request_error
  rescue_from Notifications::Client::ClientError, with: :validation_notice_request_error
  rescue_from Notifications::Client::BadRequestError, with: :validation_notice_request_error

  before_action :find_current_local_authority_from_subdomain
  before_action :prevent_caching

  attr_reader :current_local_authority

  helper_method :current_local_authority

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

  def validation_notice_request_error(exception)
    flash[:error] = "Notify was unable to send applicant email. Please contact the applicant directly."
    flash[:notice] = "Document validation successful. Application is ready for assessment."
    Appsignal.send_error(exception)
    render "planning_applications/show"
  end
end
