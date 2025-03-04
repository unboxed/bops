# frozen_string_literal: true

module BopsAdmin
  class DeterminationPeriodsController < ApplicationController
    before_action :set_pre_app_local_authority_application_type, only: %i[edit update]

    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if @pre_app_application_type.update(determination_period_days_params, :application_type_overrides)
          format.html { redirect_to setting_path, notice: t(".success") }
        else
          format.html { render :edit }
        end
      end
    end

    private

    def determination_period_days_params
      params.require(:local_authority_application_type).permit(:determination_period_days)
    end

    def set_pre_app_local_authority_application_type
      @pre_app_application_type = current_local_authority.local_authority_application_types.pre_app.take

      unless @pre_app_application_type
        redirect_to setting_path, alert: t(".not_found")
      end
    end
  end
end
