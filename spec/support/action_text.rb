# frozen_string_literal: true

require "action_text/system_test_helper"

RSpec.configure do |config|
  config.include ActionText::SystemTestHelper, type: :system
end
