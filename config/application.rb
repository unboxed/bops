# frozen_string_literal: true

require_relative "boot"
require_relative "../lib/quiet_logger"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_view/railtie"
require "grover"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bops
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.middleware.use Grover::Middleware

    # Settings in config/environments/* take precedence over those specified
    # here. Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.i18n.default_locale = :en

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Remove the error wrapper from around the form element
    config.action_view.field_error_proc = ->(html_tag, _instance) { html_tag }

    config.time_zone = "London"
    config.active_record.default_timezone = :local
    config.active_job.queue_adapter = :sidekiq
    config.action_mailer.deliver_later_queue_name = "low_priority"

    config.action_mailer.preview_path = Rails.root.join("spec/mailer/previews")

    config.active_storage.variant_processor = :mini_magick

    # Don't log certain requests that spam the log files
    config.middleware.insert_before Rails::Rack::Logger, QuietLogger, paths: ["/healthcheck"]

    config.os_vector_tiles_api_key = ENV.fetch("OS_VECTOR_TILES_API_KEY", nil)

    config.production_environment = (ENV.fetch("STAGING_ENABLED", "false") == "false")
  end
end
