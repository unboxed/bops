# frozen_string_literal: true

module BopsSubmissions
  module V1
    class AuthenticatedController < ApplicationController
      before_action :authenticate_api_user!
    end
  end
end
