# frozen_string_literal: true

RSpec.configure do |config|
  helpers = Module.new do
    def json_fixture(name, **)
      JSON.parse(file_fixture(name).read, **).with_indifferent_access
    end

    Rails::Engine.subclasses.each do |engine|
      next unless engine.name.start_with? "Bops"
      engine_name = engine.name.underscore.split(%r{[/_]+})[1]

      define_method(:"file_fixture_#{engine_name}") do |name|
        engine.root.join("spec", "fixtures", "files", name)
      end

      define_method(:"json_fixture_#{engine_name}") do |name|
        JSON.parse(engine.root.join("spec", "fixtures", name).read).with_indifferent_access
      end
    end
  end

  config.extend(helpers)
  config.include(helpers)
end
