# frozen_string_literal: true

module BopsAdmin
  class DeterminationPeriodsController < ApplicationController
    def edit
      respond_to do |format|
        format.html
      end
    end

    def update
      respond_to do |format|
        if current_local_authority.update(application_type_overrides_params, :application_type_overrides)
          format.html do
            redirect_to setting_path, notice: t(".success")
          end
        else
          format.html { render :edit }
        end
      end
    end

    private

    def application_type_overrides_params
      params.require(:local_authority).permit(application_type_overrides_attributes:)
    end

    def application_type_overrides_attributes
      [
        :code,
        :determination_period_days
      ]
    end
  end
end
