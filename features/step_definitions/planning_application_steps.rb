# frozen_string_literal: true

require "faker"

Given("I am logged in as an assessor") do
  @officer = FactoryBot.create(:user, :assessor)

  domain = @officer.local_authority.subdomain

  Capybara.default_host = "http://#{domain}.#{domain}.localhost:3000"

  visit new_user_session_path

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

Given("the planning application is invalidated") do
  steps %(
    Given I create a new document validation request for a "validation request" because "I have to"
    And I press "Invalidate application"
  )
end

Given("the planning application is validated") do
  now = Time.zone.now

  steps %(
    When I view the planning application
    And I press "Validate application"
    And I press "Validate application"
    And I fill in "Day" with "#{now.day}"
    And I fill in "Month" with "#{now.month}"
    And I fill in "Year" with "#{now.year}"
    And I press "Validate application"
  )
end

Given("the planning application is assessed") do
  steps %(
    When I view the planning application
    And I press "Assess proposal"
    And I choose "Yes"
    And I fill in "State the reasons why" with "a valid reason"
    And I fill in "supporting information" with "looks legit"
    And I press "Save"
  )
end

When("I view the planning application") do
  visit planning_application_path(@planning_application)
end
