# frozen_string_literal: true

module BopsApplicants
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    before_action :require_local_authority!
  end
end
