# frozen_string_literal: true

require "bops_submissions/engine"

module BopsSubmissions
  class << self
    def table_name_prefix
      ""
    end

    def env
      ActiveSupport::StringInquirer.new(ENV.fetch("BOPS_ENVIRONMENT", "development"))
    end
  end
end
