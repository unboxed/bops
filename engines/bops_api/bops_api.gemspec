# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "bops_api"
  spec.version = "0.1.0"
  spec.authors = ["Unboxed Consulting Ltd"]
  spec.email = ["bops@unboxedconsulting.com"]
  spec.homepage = "https://unboxed.co/"
  spec.summary = "Provides the API functionality for the BOPS system"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*"]
  end

  spec.add_dependency "rails", ">= 7.0.8", "< 7.1"
  spec.add_dependency "rswag-api", "~> 2.11"
  spec.add_dependency "rswag-specs", "~> 2.11"
  spec.add_dependency "rswag-ui", "~> 2.11"
end
