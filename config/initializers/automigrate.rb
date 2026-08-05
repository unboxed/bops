# frozen_string_literal: true

require "bops/auto_migrator"

Rails.application.config.after_initialize do
  Bops::AutoMigrator.migrate
end
