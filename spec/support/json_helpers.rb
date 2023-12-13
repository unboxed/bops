# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    def json_fixture(name, **)
      JSON.parse(File.read(Rails.root.join("spec", "fixtures", "files", name)), **)
    end
  end

  config.extend(helpers)
  config.include(helpers)
end
