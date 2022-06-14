# frozen_string_literal: true

E2E_PORT = 3333

Before("@e2e") do
  Capybara.server_host = "0.0.0.0"
  Capybara.server_port = E2E_PORT
end

After("@e2e") do
  Capybara.server_port = nil
end

Before do
  Rails.application.load_seed
end
