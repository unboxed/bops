# frozen_string_literal: true

class ApplicationController < ActionController::Base
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
end
