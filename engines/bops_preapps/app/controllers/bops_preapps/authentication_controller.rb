# frozen_string_literal: true

module BopsPreapps
  class AuthenticationController < ApplicationController
    before_action :authenticate_user!

    def user_not_authorized(_error, message = t("user_not_authorized"))
      respond_to do |format|
        format.html { redirect_to pundit_redirect_url, alert: message }
        format.json { render json: [message], status: :unauthorized }
      end
    end
  end
end
