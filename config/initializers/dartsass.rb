# frozen_string_literal: true

# govuk-frontend triggers sass deprecation warnings that we can't control
Rails.application.config.dartsass.build_options << " --quiet-deps"
