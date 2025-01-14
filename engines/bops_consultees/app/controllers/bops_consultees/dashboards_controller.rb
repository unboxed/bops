# frozen_string_literal: true

module BopsConsultees
  class DashboardsController < ApplicationController
    def show
      respond_to do |format|
        format.html
      end
    end
  end
end
