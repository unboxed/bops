# frozen_string_literal: true

require "faker"

Given("I am logged in as an assessor") do
  southwark = LocalAuthority.find_by(subdomain: "southwark")
  @officer = FactoryBot.create(:user, :assessor, local_authority: southwark)

  domain = @officer.local_authority.subdomain

  visit root_path

  Capybara.app_host = "http://#{domain}.#{domain}.localhost:#{Capybara.server_port}"

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

Given("a determined planning application") do
  @planning_application = FactoryBot.create(
    :planning_application,
    :determined,
    local_authority: @officer.local_authority
  )
end

Given("the planning application is invalidated") do
  steps %(
    Given I create a new document validation request for a "validation request" because "I have to"
    And I press "Mark the application as invalid"
  )
end

Given("the planning application is validated") do
  now = Time.zone.now

  steps %(
    When I view the planning application
    And I press "Validate application"
    And I press "Mark the application as valid"
    And I fill in "Day" with "#{now.day}"
    And I fill in "Month" with "#{now.month}"
    And I fill in "Year" with "#{now.year}"
    And I press "Mark the application as valid"
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

When("I view the planning application audit") do
  visit planning_application_audits_path(@planning_application)
end

And("the planning application has a description of {string}") do |description|
  @planning_application.update!(description: description)
end

When("I view all {string} planning applications") do |status|
  visit planning_applications_path

  click_on(status)
end

Given("the application expires in {int} days") do |n|
  @planning_application.update_column(:expiry_date, n.business_days.from_now) # rubocop:disable Rails/SkipsModelValidations
end

Then("the page contains a {string} tag containing {string}") do |colour, text|
  expect(page).to have_selector(".govuk-tag--#{colour}", text: text)
end
