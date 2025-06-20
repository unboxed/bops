# frozen_string_literal: true

module BopsCore
  module Routing
    extend ActiveSupport::Concern

    class BopsDomain
      class << self
        def matches?(request)
          tld_length = [1, request.subdomains.size].max
          domain.starts_with?(request.domain(tld_length))
        end

        private

        def domain
          Rails.application.config.domain
        end
      end
    end

    class ApplicantsDomain
      class << self
        def matches?(request)
          tld_length = [1, request.subdomains.size].max
          domain.starts_with?(request.domain(tld_length))
        end

        private

        def domain
          Rails.application.config.applicants_domain
        end
      end
    end

    class LocalAuthoritySubdomain
      class << self
        def matches?(request)
          local_authority = request.env["bops.local_authority"]
          local_authority && local_authority.subdomain == request.subdomains.first
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

    class PublicSubdomain
      class << self
        def matches?(request)
          request.subdomains.empty? || request.subdomains.first == "www"
        end
      end
    end

    def bops_domain(&)
      constraints(BopsDomain, &)
    end

    def applicants_domain(&)
      constraints(ApplicantsDomain, &)
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

    def public_subdomain(&)
      constraints(PublicSubdomain, &)
    end
  end
end
