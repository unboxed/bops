# frozen_string_literal: true

require "bops_uploads/engine"

module BopsUploads
  with_options instance_accessor: false do
    mattr_accessor :key_pair_id, :private_key, :cookie_signer
  end

  class << self
    def env
      ActiveSupport::StringInquirer.new(ENV.fetch("BOPS_ENVIRONMENT", "development"))
    end
  end
end
