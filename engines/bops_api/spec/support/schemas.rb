# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    def example_fixture(name, version: BopsApi::Schemas::DEFAULT_ODP_VERSION, **)
      JSON.parse(BopsApi::Engine.root.join("spec", "fixtures", "examples", version, name).read, **)
    end
  end

  config.extend(helpers)
  config.include(helpers)
end
