# frozen_string_literal: true

require "bops_api/engine"
require "bops_api/errors"
require "bops_api/schemas"

module BopsApi
  class << self
    def table_name_prefix
      ""
    end

    def env
      ActiveSupport::StringInquirer.new(ENV.fetch("BOPS_ENVIRONMENT", "development"))
    end
  end
end
