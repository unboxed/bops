# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/
#   Content-Security-Policy

google_tag_manager_hostname = "www.googletagmanager.com"
google_analytics_hostnames = %w[
  www.google-analytics.com
  region1.google-analytics.com
  region1.analytics.google.com
].freeze
uploads_hostname = Rails.configuration.uploads_hostname

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src :self
  policy.img_src :self, :https, :data, uploads_hostname, google_tag_manager_hostname, *google_analytics_hostnames
  policy.object_src :none
  policy.script_src :self, google_tag_manager_hostname, *google_analytics_hostnames
  policy.style_src :self, :unsafe_inline, google_tag_manager_hostname
  policy.connect_src :self, :https, google_tag_manager_hostname, *google_analytics_hostnames
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
