# frozen_string_literal: true

module BopsReports
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    before_action :require_local_authority!

    layout "application"
  end
end
