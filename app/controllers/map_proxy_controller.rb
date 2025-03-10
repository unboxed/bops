# frozen_string_literal: true

class MapProxyController < ApplicationController
  skip_before_action :verify_authenticity_token

  def proxy
    response = client.proxy

    if client.cors_allowed?
      send_data(
        response.body,
        type: response.headers["Content-Type"] || "application/octet-stream",
        disposition: "inline",
        status: response.status
      )
    else
      render plain: "CORS policy: Origin not allowed", status: :forbidden
    end
  end

  private

  def client
    @client ||= Apis::OsMap::ProxyService.new(request, response, current_local_authority)
  end
end
