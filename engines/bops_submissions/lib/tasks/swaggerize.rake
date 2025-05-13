# frozen_string_literal: true

namespace :submissions do
  namespace :docs do
    task :define_swaggerize do
      require 'rspec/core/rake_task'

      RSpec::Core::RakeTask.new('submissions:docs:swaggerize') do |t|
        # Adjust the pattern to point to your engine's specs
        t.pattern = 'engines/bops_submissions/spec/requests/**/*_spec.rb'

        t.rspec_opts = [
          '--format Rswag::Specs::SwaggerFormatter',
          '--dry-run',
          '--order defined'
        ]
      end
    end

    desc 'Generate Bops Submissions v1 Swagger documentation'
    task generate: :define_swaggerize do
      Rake::Task['submissions:docs:swaggerize'].invoke
    end
  end
end
