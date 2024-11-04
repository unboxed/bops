# frozen_string_literal: true

require "faker"

Given("I am logged out") do
  visit "/"

  click_on "Log out" if page.has_button? "Log out"
end

Given("I am logged in as a(n) {}") do |role|
  southwark = LocalAuthority.find_by(subdomain: "southwark")
  @officer = FactoryBot.create(:user, role.to_sym, local_authority: southwark, mobile_number: "07788446542")
  @api_user = FactoryBot.create(:api_user, name: "PlanX")

  domain = @officer.local_authority.subdomain
  Capybara.app_host = "http://#{domain}.#{domain}.localhost:#{Capybara.server_port}"

  step("I am logged out")
  visit "/users/sign_in"

  fill_in "Email", with: @officer.email
  fill_in "Password", with: @officer.password

  step("I enter 2FA")
end

Given("I enter 2FA") do
  click_button "Log in"

  fill_in "Security code", with: @officer.current_otp
  click_button "Enter code"
end

Given("my name is {string}") do |name|
  @officer.update!(name:)
end

Given("a new planning application") do
  @planning_application = FactoryBot.create(
    :planning_application,
    :not_started,
    :with_boundary_geojson,
    :with_constraints,
    user: @officer,
    local_authority: @officer.local_authority,
    api_user: @api_user
  )
end

Given("a validated planning application") do
  @planning_application = FactoryBot.create(
    :planning_application,
    :in_assessment,
    :with_constraints,
    local_authority: @officer.local_authority,
    api_user: @api_user
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
    And I press "Back"
    And I press "Send validation decision"
    And I press "Mark the application as invalid"
  )
end

Given("the planning application is validated") do
  steps %(
    When I view the planning application
    And I press "Check and validate"
    And I press "Send validation decision"
    And I press "Mark the application as valid"
    And I press "Mark the application as valid"
  )
end

Given("the planning application is assessed") do
  steps %(
    Given I view the planning application
    And I press "Check and assess"
    And I press "Make draft recommendation"
    And I choose "Granted" from a fieldset "What is your recommendation?"
    And I fill in "State the reasons for your recommendation." with "a valid reason"
    And I fill in "Provide supporting information for your manager." with "looks legit"
    And I press "Save and mark as complete"
  )
end

Given("a recommendation is submitted for the planning application") do
  steps %(
    Given the planning application is assessed
    And I press "Review and submit recommendation"
    And I press "Submit recommendation"
  )
end

When("I choose {string} from a fieldset {string}") do |option, fieldset|
  within_fieldset(fieldset) do
    choose option
  end
end

When("I view the planning application") do
  visit "/planning_applications/#{@planning_application.reference}"
end

When("I view the planning application audit") do
  visit "/planning_applications/#{@planning_application.reference}/audits"
end

And("the planning application has a description of {string}") do |description|
  @planning_application.update!(description:)
end

When("I view all {string} planning applications") do |status|
  visit "/planning_applications"

  click_on(status)
end

Given("the application expires in {int} days") do |n|
  @planning_application.update_column(:expiry_date, n.business_days.from_now(Date.current)) # rubocop:disable Rails/SkipsModelValidations
end

Given("the application expired {int} days ago") do |n|
  @planning_application.update_column(:expiry_date, n.business_days.ago(Date.current)) # rubocop:disable Rails/SkipsModelValidations
end

Then("the page contains a {string} tag containing {string}") do |colour, text|
  expect(page).to have_selector(".govuk-tag--#{colour}", text:)
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
    Given I press "Withdraw or cancel application"
    And I choose "Withdrawn by applicant"
    And I fill in "Provide a reason" with "Applicant is moving to Bermuda, because heck this"
    And I press "Withdraw or cancel application"
  )
end

Given "the application is returned by the applicant" do
  steps %(
    Given I press "Withdraw or cancel application"
    When I choose "Returned as invalid"
    And I fill in "Provide a reason" with "Applicant sent selfies instead of floor plans"
    And I press "Withdraw or cancel application"
  )
end

Then("the assess proposal accordion displays a {string} tag") do |tag|
  within(:xpath, '//*[@id="assess-section"]') do
    expect(page).to have_content tag
  end
end

Then("the complete assessment accordion displays a {string} tag") do |tag|
  within(:xpath, '//*[@id="complete-assessment-tasks"]') do
    expect(page).to have_content tag
  end
end

Given "a draft assessment on the planning application" do
  steps %(
    Given the planning application is validated
    And I view the planning application
    And I press "Check and assess"
    And I press "Make draft recommendation"
    When I fill in "State the reasons for your recommendation." with "Lawful as can be"
    And I fill in "Provide supporting information for your manager." with "I'm hoping you feel supported"
    And I press "Save and come back later"
  )
end
