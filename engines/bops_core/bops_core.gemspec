# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "bops_core"
  spec.version = "0.1.0"
  spec.authors = ["Unboxed Consulting Ltd"]
  spec.email = ["bops@unboxedconsulting.com"]
  spec.homepage = "https://unboxed.co/"
  spec.summary = "Provides shared functionality for all BOPS components"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*"]
  end

  spec.add_dependency "rails", "~> 8.0"
  spec.add_dependency "govuk-components", "~> 5", ">= 5.8.0"
  spec.add_dependency "govuk_design_system_formbuilder", "~> 5", ">= 5.8.0"
  spec.add_dependency "pagy"
end
