# frozen_string_literal: true

module BopsAdmin
  class SettingsController < ApplicationController
    before_action :set_application_type_overrides

    def show
      respond_to do |format|
        format.html
      end
    end

    private

    def set_application_type_overrides
      @application_type_overrides = current_local_authority.application_type_overrides
    end
  end
end
