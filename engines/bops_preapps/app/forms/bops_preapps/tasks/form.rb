# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class Form < BopsCore::Tasks::Form
      include BopsPreapps::Engine.routes.url_helpers
    end
  end
end
