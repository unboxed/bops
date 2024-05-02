# frozen_string_literal: true

require "govuk/components"

module BopsCore
  class Engine < ::Rails::Engine
    isolate_namespace BopsCore
  end
end
