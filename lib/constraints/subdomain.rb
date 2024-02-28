# frozen_string_literal: true

module Constraints
  class LocalAuthoritySubdomain
    class << self
      def matches?(request)
        LocalAuthority.pluck(:subdomain).include?(request.subdomain)
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
        Constraints::ConfigSubdomain.matches?(request) || Constraints::LocalAuthoritySubdomain.matches?(request)
      end
    end
  end
end
