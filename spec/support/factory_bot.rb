# frozen_string_literal: true

require "factory_bot"

# Make `file_fixture` and `fixture_file_upload` available in factories
helpers = Module.new do
  extend ActiveSupport::Concern
  include ActionDispatch::TestProcess
  include ActiveSupport::Testing::FileFixtures

  included do
    self.file_fixture_path = RSpec.configuration.file_fixture_path
  end
end

FactoryBot::SyntaxRunner.include(helpers)

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
