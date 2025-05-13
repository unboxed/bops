# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    def json_fixture(name, **opts)
      JSON.parse(BopsSubmissions::Engine.root.join("spec", "fixtures", name).read, symbolize_names: true, **opts)
    end
  end

  config.extend(helpers)
  config.include(helpers)
end
