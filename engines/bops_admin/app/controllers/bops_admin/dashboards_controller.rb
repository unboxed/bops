# frozen_string_literal: true

module BopsAdmin
  class DashboardsController < ApplicationController
    self.page_key = "dashboard"

    def show
      respond_to do |format|
        format.html
      end
    end
  end
end
