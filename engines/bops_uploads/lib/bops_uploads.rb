# frozen_string_literal: true

require "bops_uploads/engine"

module BopsUploads
  class << self
    def env
      ActiveSupport::StringInquirer.new(ENV.fetch("BOPS_ENVIRONMENT", "development"))
    end
  end
end
