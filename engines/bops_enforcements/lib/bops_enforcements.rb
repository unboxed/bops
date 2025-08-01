# frozen_string_literal: true

require "bops_enforcements/engine"

module BopsEnforcements
  class << self
    def table_name_prefix
      ""
    end

    def env
      ActiveSupport::StringInquirer.new(ENV.fetch("BOPS_ENVIRONMENT", "development"))
    end
  end
end
