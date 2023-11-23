# frozen_string_literal: true

namespace :api do
  namespace :docs do
    # Dynamically define the swaggerize task so that we don't
    # load rspec/core without monkey patching disabled
    task :define_swaggerize do
      require "rspec/core/rake_task"

      RSpec::Core::RakeTask.new("api:docs:swaggerize") do |t|
        t.pattern = "engines/bops_api/spec/requests/**/*_spec.rb"

        t.rspec_opts = [
          "--format Rswag::Specs::SwaggerFormatter",
          "--dry-run",
          "--order defined"
        ]
      end
    end

    desc "Generate API v2 Swagger documentation"
    task generate: :define_swaggerize do
      Rake::Task["api:docs:swaggerize"].invoke
    end
  end
end
