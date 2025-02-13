# frozen_string_literal: true

module BopsCore
  module Middleware
    class LocalAuthority
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        env["bops.local_authority"] = ::LocalAuthority.find_by(subdomain: request.subdomain)

        @app.call(env)
      end
    end
  end
end
