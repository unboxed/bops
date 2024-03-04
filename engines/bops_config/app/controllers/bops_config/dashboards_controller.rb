# frozen_string_literal: true

module BopsConfig
  class DashboardsController < ApplicationController
    def show
      respond_to do |format|
        format.html
      end
    end
  end
end
