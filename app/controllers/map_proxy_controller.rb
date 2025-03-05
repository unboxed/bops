# frozen_string_literal: true

require "faraday"

class MapProxyController < ApplicationController
  skip_before_action :verify_authenticity_token

  def proxy
    faraday_response = proxy_to_ordnance_survey(build_os_url)
    configure_response_headers
    send_response(faraday_response)
  end

  private

  def build_os_url
    os_path = request.fullpath.sub("/map_proxy", "")
    "https://api.os.uk#{os_path}"
  end

  def proxy_to_ordnance_survey(url)
    conn = Faraday.new(url: url) do |faraday|
      faraday.response :raise_error
      faraday.adapter Faraday.default_adapter
    end

    conn.get do |req|
      req.params = request.query_parameters
      req.headers["key"] = Rails.configuration.os_vector_tiles_api_key
      req.headers["Accept"] = "application/octet-stream"
    end
  end

  def configure_response_headers
    response.headers["Cross-Origin-Resource-Policy"] = "cross-origin"
    response.headers["Access-Control-Allow-Origin"] = origin if cors_allowed? && origin.present?
  end

  def cors_allowed?
    return true if origin.nil? # Same-origin requests are allowed

    local_authority = LocalAuthority.find_by(subdomain: request_subdomain)
    if local_authority && origin == local_authority.applicants_url
      true
    else
      Rails.logger.warn "CORS denied for origin: #{origin}"
      false
    end
  end

  def origin
    request.headers["Origin"]
  end

  def request_subdomain
    request.host.split(".").first.downcase
  end

  def send_response(faraday_response)
    if cors_allowed?
      send_data(
        faraday_response.body,
        type: faraday_response.headers["Content-Type"] || "application/octet-stream",
        disposition: "inline",
        status: faraday_response.status
      )
    else
      render plain: "CORS policy: Origin not allowed", status: :forbidden
    end
  end
end
