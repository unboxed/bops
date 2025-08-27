# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    def zip_fixture(name)
      BopsSubmissions::Engine.root.join("spec", "fixtures", "files", name).to_s
    end
  end

  config.extend(helpers)
  config.include(helpers)
end
