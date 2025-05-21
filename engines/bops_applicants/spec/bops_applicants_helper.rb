# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.before type: :request do
    host!("planx.bops-applicants.services")
  end

  config.before type: :system do
    Capybara.app_host = "http://planx.bops-applicants.services"
  end
end
