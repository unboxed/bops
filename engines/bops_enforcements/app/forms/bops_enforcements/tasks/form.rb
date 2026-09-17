# frozen_string_literal: true

module BopsEnforcements
  module Tasks
    class Form
      include BopsCore::Tasks::Form
      include BopsEnforcements::Engine.routes.url_helpers
      include BopsEnforcements::Engine.routes.mounted_helpers
    end
  end
end
