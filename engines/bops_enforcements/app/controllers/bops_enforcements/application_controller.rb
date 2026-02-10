# frozen_string_literal: true

module BopsEnforcements
  class ApplicationController < BopsCore::ApplicationController
    include BopsCore::Sidebar

    before_action :require_local_authority!
    before_action :authenticate_user!

    layout "application"
  end
end
