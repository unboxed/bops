# frozen_string_literal: true

module RSpec
  module Rails
    module ServiceExampleGroup
      extend ActiveSupport::Concern
      include RSpec::Rails::RailsExampleGroup
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Rails::ServiceExampleGroup, type: :service)
end
