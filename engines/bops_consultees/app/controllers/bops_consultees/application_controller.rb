# frozen_string_literal: true

module BopsConsultees
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController
    include BopsCore::MagicLinkAuthenticatable

    layout "application"
  end
end
