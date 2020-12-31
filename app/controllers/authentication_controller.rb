# frozen_string_literal: true

class AuthenticationController < ApplicationController
  include Pundit

  before_action :authenticate_user!

  # rubocop:disable Rails/LexicallyScopedActionFilter
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index
  # rubocop:enable Rails/LexicallyScopedActionFilter

  rescue_from ActionController::InvalidAuthenticityToken, with: :please_retry
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def pundit_redirect_url
    request.referer || root_path
  end

  def user_not_authorized(_e, message = t("user_not_authorized"))
    respond_to do |format|
      format.html { redirect_to pundit_redirect_url, alert: message }
      format.json { render json: [message], status: :unauthorized }
    end
  end

private

  def please_retry(_exception)
    reset_session

    redirect_to request.referer
  end
end
