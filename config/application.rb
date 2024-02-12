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
    config.load_defaults 7.1

    config.middleware.use Grover::Middleware

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    # config.autoload_lib(ignore: %w[assets tasks])

    # Settings in config/environments/* take precedence over those specified
    # here. Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
    config.i18n.default_locale = :en
    config.i18n.available_locales = %i[en]

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Remove the error wrapper from around the form element
    config.action_view.field_error_proc = ->(html_tag, _instance) { html_tag }

    config.time_zone = "London"
    config.active_record.default_timezone = :local
    config.active_job.queue_adapter = :sidekiq
    config.action_mailer.deliver_later_queue_name = "low_priority"

    config.action_mailer.preview_paths = [Rails.root.join("spec/mailer/previews")]

    config.active_storage.variant_processor = :mini_magick

    # Don't log certain requests that spam the log files
    config.middleware.insert_before Rails::Rack::Logger, QuietLogger, paths: ["/healthcheck"]

    # don't fail tests in this case
    config.active_record.raise_on_assign_to_attr_readonly = false

    # use rails 7.0 encryption method
    config.active_record.encryption.hash_digest_class = OpenSSL::Digest::SHA256

    # changing this breaks some creation_service tests
    config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction = true

    config.os_vector_tiles_api_key = ENV["OS_VECTOR_TILES_API_KEY"]
    config.feedback_fish_id = ENV["FEEDBACK_FISH_ID"]
    config.google_tag_manager_id = ENV["GOOGLE_TAG_MANAGER_ID"]

    config.default_notify_api_key = ENV["NOTIFY_API_KEY"]
    config.default_notify_template_id = ENV.fetch("DEFAULT_NOTIFY_TEMPLATE_ID", "7a7c541e-be0a-490b-8165-8e44dc9d13ad")
    config.notify_letter_api_key = ENV["NOTIFY_LETTER_API_KEY"]
    config.otp_secret_encryption_key = ENV["OTP_SECRET_ENCRYPTION_KEY"]
    config.paapi_url = ENV.fetch("PAAPI_URL", "https://staging.paapi.services/api/v1")
    config.planning_history_enabled = ENV["PLANNING_HISTORY_ENABLED"] == true
    config.planx_file_api_key = ENV["PLANX_FILE_API_KEY"]
    config.planx_file_production_api_key = ENV["PLANX_FILE_PRODUCTION_API_KEY"]
    config.staging_api_bearer = ENV["STAGING_API_BEARER"]
    config.staging_api_url = ENV["STAGING_API_URL"]
  end

  def self.env
    ActiveSupport::StringInquirer.new(ENV.fetch("BOPS_ENVIRONMENT", "development"))
  end
end
