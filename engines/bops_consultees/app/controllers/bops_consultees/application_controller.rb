# frozen_string_literal: true

module BopsConsultees
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController
    include BopsCore::MagicLinkAuthenticatable

    before_action :authenticate_with_sgid!

    layout "application"
  end
end
