# frozen_string_literal: true

class Api::V1::ApplicationController < ApplicationController
  before_action :authenticate, :set_default_format
  protect_from_forgery with: :null_session

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end

  def set_default_format
    request.format = :json
  end

  def json_request?
    request.format.json?
  end

  def set_cors_headers
    response.set_header("Access-Control-Allow-Origin", "*")
    response.set_header("Access-Control-Allow-Methods", "*")
    response.set_header(
      "Access-Control-Allow-Headers",
      "Origin, X-Requested-With, Content-Type, Accept"
    )
    response.charset = "utf-8"
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token, _options|
      ApiUser.find_by(token: token)
    end
  end

  def current_api_user
    @current_api_user ||= authenticate
  end

  protected

  def request_http_token_authentication(realm = "Application", message = nil)
    self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
    render json: { error: "HTTP Token: Access denied." }, status: :unauthorized
  end
end
