# frozen_string_literal: true

module BopsSubmissions
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController
    include ErrorHandler

    protect_from_forgery with: :null_session, prepend: true

    before_action :require_local_authority!

    layout "application"
  end
end
