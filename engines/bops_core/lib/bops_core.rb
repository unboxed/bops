# frozen_string_literal: true

require "bops_core/engine"
require "bops_core/routing"
require "bops_core/middleware"

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
