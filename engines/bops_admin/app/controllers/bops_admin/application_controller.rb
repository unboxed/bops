# frozen_string_literal: true

module BopsAdmin
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    before_action :require_local_authority!
    before_action :authenticate_user!
    before_action :require_administrator!
    before_action :set_back_path

    layout "application"
  end
end
