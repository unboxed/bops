# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.before type: :system do |example|
    Capybara.app_host = "http://config.bops.services"
  end
end
