# frozen_string_literal: true

namespace :submission_api do
  namespace :docs do
    task :define_swaggerize do
      require "rspec/core/rake_task"

      RSpec::Core::RakeTask.new("submission_api:docs:swaggerize") do |t|
        t.pattern = "engines/bops_submissions/spec/requests/**/*_spec.rb"

        t.rspec_opts = [
          "-I", BopsSubmissions::Engine.root.join("spec").to_s,
          "--require", "swagger_helper",
          "--format Rswag::Specs::SwaggerFormatter",
          "--dry-run",
          "--order defined"
        ]
      end
    end

    desc "Generate Submissions API Swagger documentation"
    task generate: :define_swaggerize do
      Rake::Task["submission_api:docs:swaggerize"].invoke
    end
  end
end
