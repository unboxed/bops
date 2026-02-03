# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class Form
      include BopsCore::Tasks::Form
      include BopsPreapps::Engine.routes.url_helpers
      include BopsPreapps::Engine.routes.mounted_helpers
    end
  end
end
