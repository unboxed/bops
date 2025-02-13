# frozen_string_literal: true

module BopsCore
  module Middleware
    class User
      def initialize(app, global_subdomains: %w[])
        @app = app
        @global_subdomains = global_subdomains
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        env["bops.user_scope"] = user_scope(request.subdomain, env["bops.local_authority"])

        @app.call(env)
      end

      private

      def user_scope(subdomain, local_authority)
        if global?(subdomain)
          ::User.global.kept
        elsif local_authority.present?
          local_authority.users.kept
        else
          ::User.none
        end
      end

      def global?(subdomain)
        @global_subdomains.include?(subdomain)
      end
    end
  end
end
