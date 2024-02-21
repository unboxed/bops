# frozen_string_literal: true

# govuk-frontend triggers sass deprecation warnings that we can't control
# see https://github.com/alphagov/govuk-frontend/issues/2238
#
# the docs suggest quiet-deps alone should be enough but quiet seems to be needed too
Rails.application.config.dartsass.build_options << " --quiet-deps --quiet"
