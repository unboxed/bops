# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :prevent_caching

  private

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = 100.years.ago
  end
end
