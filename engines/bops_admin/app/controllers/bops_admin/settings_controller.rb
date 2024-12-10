# frozen_string_literal: true

module BopsAdmin
  class SettingsController < ApplicationController
    def show
      respond_to do |format|
        format.html
      end
    end
  end
end
