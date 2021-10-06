# frozen_string_literal: true

require "faker"

Given("I am logged in as an assessor") do
  @officer = FactoryBot.create(:user, :assessor)

  domain = @officer.local_authority.subdomain

  url = URI.join("http://#{domain}.#{domain}.localhost:3000", new_user_session_path)

  visit url

  fill_in "Email", with: @officer.email
  fill_in "Password", with: @officer.password

  click_button "Log in"
end

Given("a new planning application") do
  @planning_application = FactoryBot.create(
    :planning_application,
    :not_started,
    local_authority: @officer.local_authority
  )
end

When("I view the planning application") do
  visit current_url + planning_application_path(@planning_application)
end
