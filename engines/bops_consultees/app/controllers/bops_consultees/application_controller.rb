# frozen_string_literal: true

module BopsConsultees
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController

    layout "application"
  end
end
