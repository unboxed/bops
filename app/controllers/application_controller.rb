# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :prevent_caching

  private

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = 100.years.ago
  end

  def disable_flash_header
    @disable_flash_header = true
  end

  def current_council
    if request.subdomains.any?
      Council.find_by! subdomain: request.subdomain
    else
      false
    end
  end
  helper_method :current_council
end
