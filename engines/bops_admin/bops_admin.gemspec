# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "bops_admin"
  spec.version = "0.1.0"
  spec.authors = ["Unboxed Consulting Ltd"]
  spec.email = ["bops@unboxedconsulting.com"]
  spec.homepage = "https://unboxed.co/"
  spec.summary = "Provides the local authority admin functionality for the BOPS system"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*"]
  end

  spec.add_dependency "rails", ">= 7.1.3", "< 7.2"
  spec.add_dependency "pagy"
end
