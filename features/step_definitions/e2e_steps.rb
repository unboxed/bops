# frozen_string_literal: true

When("I switch to BOPS") do
  Capybara.app_host = "http://southwark.southwark.localhost:#{Capybara.server_port}"
end

When("I switch to BOPS-applicants") do
  Capybara.app_host = "http://southwark.southwark.applicants:3001"
end
