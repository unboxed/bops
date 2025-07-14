# frozen_string_literal: true

module BopsSubmissions
  class ApplicationController < ActionController::Base
    include BopsCore::ApplicationController
    include BopsApi::SchemaValidation
    include ErrorHandler

    protect_from_forgery with: :null_session, prepend: true
    wrap_parameters false

    before_action :require_local_authority!

    layout "application"
  end
end
