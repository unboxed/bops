# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "bops_preapps"
  spec.version = "0.1.0"
  spec.authors = ["Unboxed Consulting Ltd"]
  spec.email = ["bops@unboxedconsulting.com"]
  spec.homepage = "https://unboxed.co/"
  spec.summary = "Provides the interface for pre apps using BOPS"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*"]
  end

  spec.add_dependency "bops_core", "0.1.0"
end
