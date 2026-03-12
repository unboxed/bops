# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    google_tag_manager_hostname = "www.googletagmanager.com"
    google_analytics_hostnames = %w[
      www.google-analytics.com
      region1.google-analytics.com
      region1.analytics.google.com
    ].freeze
    openlayers_map_url = "https://cdn.skypack.dev/ol@%5E6.6.1/ol.css"
    policy.default_src :self, :https
    policy.font_src :self
    policy.img_src :self, :https, :data, :blob, google_tag_manager_hostname, *google_analytics_hostnames
    policy.object_src :none
    policy.script_src :self, google_tag_manager_hostname, *google_analytics_hostnames
    policy.style_src :self, :unsafe_inline, openlayers_map_url, google_tag_manager_hostname
    policy.connect_src :self, :https, google_tag_manager_hostname, *google_analytics_hostnames
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  # Automatically add `nonce` to `javascript_tag`, `javascript_include_tag`, and `stylesheet_link_tag`
  # if the corresponding directives are specified in `content_security_policy_nonce_directives`.
  # config.content_security_policy_nonce_auto = true

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
