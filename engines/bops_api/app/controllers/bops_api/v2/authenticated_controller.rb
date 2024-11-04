# frozen_string_literal: true

module BopsApi
  module V2
    class AuthenticatedController < ApplicationController
      before_action :authenticate_api_user!

      def planning_applications_scope
        current_local_authority.planning_applications.includes(:user)
      end
    end
  end
end
