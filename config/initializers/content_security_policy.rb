# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/
#   Content-Security-Policy

GOOGLE_TAG_MANAGER_HOSTNAME = "www.googletagmanager.com"
GOOGLE_ANALYTICS_HOSTNAMES = %w[
  www.google-analytics.com
  region1.google-analytics.com
  region1.analytics.google.com
].freeze

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src :self, :https, :data
  policy.img_src :self, :https, :data, GOOGLE_TAG_MANAGER_HOSTNAME, *GOOGLE_ANALYTICS_HOSTNAMES
  policy.object_src :none
  policy.script_src :self, :https, GOOGLE_TAG_MANAGER_HOSTNAME, *GOOGLE_ANALYTICS_HOSTNAMES
  policy.style_src :self, :https, :unsafe_inline, GOOGLE_TAG_MANAGER_HOSTNAME
  policy.connect_src :self, :https, GOOGLE_TAG_MANAGER_HOSTNAME, *GOOGLE_ANALYTICS_HOSTNAMES
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]
