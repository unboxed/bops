# frozen_string_literal: true

module BopsSubmissions
  module V2
    class AuthenticatedController < ApplicationController
      before_action :authenticate_api_user!

      private

      def required_api_key_scope = "planning_application"
    end
  end
end
