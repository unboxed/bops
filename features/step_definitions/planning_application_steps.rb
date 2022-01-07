# frozen_string_literal: true

require "faker"

Given("I am logged out") do
  visit root_path

  click_on "Log out" if page.has_button? "Log out"
end

Given("I am logged in as a(n) {}") do |role|
  step("I am logged out")

  southwark = LocalAuthority.find_by(subdomain: "southwark")
  @officer = FactoryBot.create(:user, role.to_sym, local_authority: southwark)

  domain = @officer.local_authority.subdomain

  visit root_path

  Capybara.app_host = "http://#{domain}.#{domain}.localhost:#{Capybara.server_port}"

  visit new_user_session_path

  fill_in "Email", with: @officer.email
  fill_in "Password", with: @officer.password

  click_button "Log in"
end

Given("my name is {string}") do |name|
  @officer.update!(name: name)
end

Given("a new planning application") do
  @planning_application = FactoryBot.create(
    :planning_application,
    :not_started,
    local_authority: @officer.local_authority
  )
end

Given("a new application of type prior approval") do
  @planning_application = FactoryBot.create(:planning_application,
                                            :prior_approval,
                                            local_authority: @officer.local_authority)
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
    Given I view the planning application
    And I press "Assess proposal"
    And I choose "Yes"
    And I fill in "State the reasons why" with "a valid reason"
    And I fill in "supporting information" with "looks legit"
    And I press "Save and mark as complete"
  )
end

Given("a recommendation is submitted for the planning application") do
  steps %(
    Given the planning application is validated
    And the planning application is assessed
    And I press "Submit recommendation"
    And I press "Submit to manager"
  )
end

Given("the planning application is determined") do
  steps %(
    Given a recommendation is submitted for the planning application
    And I press "Review assessment"
    And I choose "Yes" for "Do you agree with the recommendation?"
    And I press "Save"
    And I press "Publish determination"
    And I press "Determine application"
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

Given("the application expired {int} days ago") do |n|
  @planning_application.update_column(:expiry_date, n.business_days.ago) # rubocop:disable Rails/SkipsModelValidations
end

Then("the page contains a {string} tag containing {string}") do |colour, text|
  expect(page).to have_selector(".govuk-tag--#{colour}", text: text)
end

Then("there is a relevant proposal detail for {string} with a response of {string}") do |question, response|
  within(".result_information ol") do
    expect(page).to have_selector("li", text: [question, response].join("\n"))
  end
end

Given("I edit the planning application's details") do
  steps %(
    Given I view the planning application
    And I press "Application information"
    And I press "Edit details"
  )
end

Given "the application is withdrawn by the applicant" do
  steps %(
    Given I press "Cancel application"
    And I choose "Withdrawn by applicant"
    And I fill in "Can you provide more detail?" with "Applicant is moving to Bermuda, because heck this"
    And I press "Save"
  )
end

Given "the application is returned by the applicant" do
  steps %(
    Given I press "Cancel application"
    When I choose "Returned as invalid"
    And I fill in "Can you provide more detail?" with "Applicant sent selfies instead of floor plans"
    And I press "Save"
  )
end

Then("the assess proposal accordion displays a {string} tag") do |tag|
  within(:xpath, '//*[@id="assess-section"]') do
    expect(page).to have_content tag
  end
end

Given "a draft assessment on the planning application" do
  steps %(
    Given the planning application is validated
    And I view the planning application
    And I press "Assess proposal"
    When I fill in "State the reasons why this application is, or is not lawful." with "Lawful as can be"
    And I fill in "Please provide supporting information for your manager." with "I'm hoping you feel supported"
    And I press "Save and come back later"
  )
end
