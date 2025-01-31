# frozen_string_literal: true

class AuthenticationController < ApplicationController
  before_action :authenticate_user!
  before_action :reset_session_and_redirect, unless: :session_domain_matches?

  rescue_from ActionController::InvalidAuthenticityToken, with: :reset_session_and_redirect

  def user_not_authorized(_error, message = t("user_not_authorized"))
    respond_to do |format|
      format.html { redirect_to pundit_redirect_url, alert: message }
      format.json { render json: [message], status: :unauthorized }
    end
  end
end
