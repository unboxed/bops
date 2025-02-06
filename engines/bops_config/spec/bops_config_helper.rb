# frozen_string_literal: true

require "rails_helper"

Dir[BopsCore::Engine.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.before type: :controller do |example|
    request.set_header("HTTP_HOST", "config.bops.services")
  end

  config.before type: :system do |example|
    Capybara.app_host = "http://config.bops.services"
  end
end
