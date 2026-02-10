# frozen_string_literal: true

module BopsReports
  class ApplicationController < BopsCore::ApplicationController

    before_action :require_local_authority!

    layout "application"
  end
end
