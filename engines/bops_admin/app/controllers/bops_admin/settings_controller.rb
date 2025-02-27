# frozen_string_literal: true

module BopsAdmin
  class SettingsController < ApplicationController
    before_action :set_pre_app_local_authority_application_type, only: %i[show]

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def set_pre_app_local_authority_application_type
      @pre_app_application_type = current_local_authority.local_authority_application_types.pre_app.take

      unless @pre_app_application_type
        redirect_to setting_path, alert: t(".not_found")
      end
    end
  end
end
