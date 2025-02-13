# frozen_string_literal: true

module BopsCore
  module Routing
    extend ActiveSupport::Concern

    class LocalAuthoritySubdomain
      class << self
        def matches?(request)
          local_authority = request.env["bops.local_authority"]
          local_authority && local_authority.subdomain == request.subdomain
        end
      end
    end

    class ConfigSubdomain
      class << self
        def matches?(request)
          request.subdomain == "config"
        end
      end
    end

    class DeviseSubdomain
      class << self
        def matches?(request)
          ConfigSubdomain.matches?(request) || LocalAuthoritySubdomain.matches?(request)
        end
      end
    end

    class UploadsSubdomain
      class << self
        def matches?(request)
          request.subdomain == "uploads"
        end
      end
    end

    def local_authority_subdomain(&)
      constraints(LocalAuthoritySubdomain, &)
    end

    def config_subdomain(&)
      constraints(ConfigSubdomain, &)
    end

    def devise_subdomain(&)
      constraints(DeviseSubdomain, &)
    end

    def uploads_subdomain(&)
      constraints(UploadsSubdomain, &)
    end
  end
end
