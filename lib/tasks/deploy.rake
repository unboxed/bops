# frozen_string_literal: true

require "package_builder"

# rubocop:disable Rails/RakeEnvironment
namespace :deploy do
  desc "Build an application package"
  task :build do
    PackageBuilder.build!
  end

  desc "Build and deploy the website to the preview stack"
  task :preview do
    PackageBuilder.deploy!(:preview)
  end

  desc "Build and deploy the website to the pentest stack"
  task :pentest do
    PackageBuilder.deploy!(:pentest)
  end

  desc "Build and deploy the website to the production stack"
  task :production do
    PackageBuilder.deploy!(:production)
  end
end
# rubocop:enable Rails/RakeEnvironment
