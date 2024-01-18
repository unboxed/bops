# frozen_string_literal: true

# https://github.com/heartcombo/devise/wiki/How-To:-Send-emails-from-subdomains

module SubdomainHelper
  def with_subdomain(subdomain)
    subdomain ||= ""
    subdomain += "." unless subdomain.empty?
    host = Rails.application.config.action_mailer.default_url_options[:host]
    [subdomain, host].join
  end

  def url_for(options = nil)
    options[:host] = with_subdomain(options.delete(:subdomain)) if options.is_a?(Hash) && options.key?(:subdomain)
    super
  end
end
