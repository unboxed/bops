# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "bops_submissions"
  spec.version = "0.1.0"
  spec.authors = ["Unboxed Consulting Ltd"]
  spec.email = ["bops@unboxedconsulting.com"]
  spec.homepage = "https://unboxed.co/"
  spec.summary = "Provides the submissions functionality for the BOPS system"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*"]
  end

  spec.add_dependency "bops_core", "0.1.0"
  spec.add_dependency "rswag-api", "~> 2.14"
  spec.add_dependency "rswag-specs", "~> 2.14"
  spec.add_dependency "rswag-ui", "~> 2.14"
  spec.add_dependency "rubyzip", "~> 2.4.1"
end
