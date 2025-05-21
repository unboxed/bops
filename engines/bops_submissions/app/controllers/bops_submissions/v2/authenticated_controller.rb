# frozen_string_literal: true

module BopsSubmissions
  module V2
    class AuthenticatedController < ApplicationController
      before_action :authenticate_api_user!
    end
  end
end
