# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    def json_fixture(name, **)
      JSON.parse(Rails.root.join("spec", "fixtures", "files", name).read, **)
    end

    def api_json_fixture(name, **)
      JSON.parse(BopsApi::Engine.root.join("spec", "fixtures", "examples", name).read, **)
    end
  end

  config.extend(helpers)
  config.include(helpers)
end
