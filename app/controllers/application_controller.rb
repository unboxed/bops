# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :find_current_local_authority_from_subdomain
  before_action :prevent_caching

  attr_reader :current_local_authority
  helper_method :current_local_authority

  private

  def find_current_local_authority_from_subdomain
    unless @current_local_authority ||= LocalAuthority.find_by(subdomain: request.subdomain)
      render plain: "No Local Authority Found", status: 404
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
