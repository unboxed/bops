# frozen_string_literal: true

require "bops_core/engine"
require "bops_core/errors"
require "bops_core/middleware"
require "bops_core/public_exceptions"
require "bops_core/routing"

module BopsCore
  class << self
    def table_name_prefix
      ""
    end

    def env
      ActiveSupport::StringInquirer.new(ENV.fetch("BOPS_ENVIRONMENT", "development"))
    end
  end
end
