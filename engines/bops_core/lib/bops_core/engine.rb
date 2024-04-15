# frozen_string_literal: true

module BopsCore
  class Engine < ::Rails::Engine
    isolate_namespace BopsCore
  end
end
