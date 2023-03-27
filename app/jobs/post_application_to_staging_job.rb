# frozen_string_literal: true

class PostApplicationToStagingJob < ApplicationJob
  queue_as :default

  def perform(local_authority, planning_application)
    HTTParty.post(
      "https://southwark.bops-staging.services/api/v1/planning_applications",
      headers: { Authorization: authorization_header },
      body: JSON.parse(planning_application.audit_log)
    )
  end

  private

  def api_base
    "#{local_authority.subdomain}.#{ENV.fetch('DOMAIN')}"
  end

  def endpoint
    "planning_applications"
  end

  def authorization_header
    "Bearer #{Staging API User token}"
    # {ENV.fetch('API_BEARER')}"
  end
end
