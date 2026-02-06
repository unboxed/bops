# frozen_string_literal: true

module Tasks
  class Form
    include BopsCore::Tasks::Form
    include Rails.application.routes.url_helpers
  end
end
