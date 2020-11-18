# frozen_string_literal: true

class ApplicationController < ActionController::Base
  set_current_tenant_by_subdomain(:local_planning_authority, :subdomain)

  before_action :prevent_caching

  before_action do
    debugger
  end

  private

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = 100.years.ago
  end

  def disable_flash_header
    @disable_flash_header = true
  end
end
