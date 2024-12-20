# frozen_string_literal: true

When("I view the application's validations requests") do
  visit "/planning_applications/#{@planning_application.reference}/validation/validation_requests"
end

When("I start the validation wizard") do
  visit "/planning_applications/#{@planning_application.reference}/validation/tasks"
end

When("I create a new document validation request for a(n) {string} because {string}") do |type, reason|
  steps %(
    Given I start the validation wizard
    And I press "Check and request documents"
    And I press "Add a request for a missing document"
    And I fill in "Please specify the new document type:" with "#{type}"
    And I fill in "the reason" with "#{reason}"
    And I save or send the request
    And I press "Validation tasks"
    And I click link "Review validation requests"
  )
end

Then("there is a validation request for a(n) {string} that shows {string}") do |request_details, status|
  table = page.find(".validation-requests-table")

  expect(table).to have_selector(:table_row, "Detail" => request_details, "Status" => status)
end

Then("there is a validation request for a(n) {string} that has a link {string}") do |request_details, link|
  table = page.find(:table, "Validation requests")

  expect(table).to have_selector(:table_row, "Detail" => request_details, "Actions" => link)
end

Then("there is a validation request for a(n) {string} that does not have a link {string}") do |request_details, link|
  table = page.find(:table, "Validation requests")

  expect(table).to_not have_selector(:table_row, "Detail" => request_details, "Actions" => link)
end

Then("there is a cancelled validation request for a(n) {string} that shows {string}") do |reason, date|
  table = page.find(:table, "Cancelled requests")

  expect(table).to have_selector(:table_row, "Reason for cancellation" => reason, "Date cancelled" => date)
end

Then("there is no validation request for a {string}") do |request_details|
  table = page.find(".validation-requests-table")

  expect(table).to_not have_selector(:table_row, "Detail" => request_details)
end

Given("I add a new validation request") do
  steps %(
    Given I view the application's validations requests
    And I press "Add new request"
  )
end

Given("I create a(n) additional document validation request with {string}") do |details|
  steps %(
    Given I start the validation wizard
    And I press "Check and request documents"
    And I press "Add a request for a missing document"
    And I fill in "Please specify the new document type:" with "#{details}"
    And I fill in "the reason" with "a valid reason"
    And I save or send the request
    And I press "Validation tasks"
    And I click link "Review validation requests"
  )
end

Given("I create a(n) other change validation request with {string}") do |details|
  steps %(
    Given I start the validation wizard
    And I press "Add another validation request"
    And I fill in "Tell the applicant" with "#{details}"
    And I fill in "Explain to the applicant" with "Please make the change"
    And I save or send the request
    And I click link "Review validation requests"
  )
end

Given("I create a red line boundary change validation request with {string}") do |details|
  # we can't simulate drawing a new map, not now anyway
  FactoryBot.create(
    :red_line_boundary_change_validation_request,
    state: "pending",
    planning_application: @planning_application,
    reason: details
  )

  # force a refresh as we've gone under the hood here
  visit current_path
end

When("I save or send the request") do
  if @planning_application.reload.invalidated?
    steps %(
      And I press "Send request"
    )
  else
    steps %(
      And I press "Save request"
    )
  end
end

# Cancel validation requests

When("I see the cancel confirmation form actions") do
  within(".govuk-button-group") do
    steps %(
      Then the page has button "Confirm cancellation"
      And the page has a "Back" link
    )
  end
end

Given("I cancel a validation request for a {string} with {string}") do |details, reason|
  steps %(
    Given I click link "View and update" in table row for "#{details}"
    And I click link "Cancel request" in table row for "#{details}"
    Then I fill in "Explain to the applicant why this request is being cancelled" with "#{reason}"
    And I press "Confirm cancellation"
    Then an email is sent to the applicant confirming the validation request cancellation
  )
end

Given("I cancel a(n) additional document validation request with {string}") do |details|
  steps %(
    Given I create an additional document validation request with "Picture of funny meme"
    And I click link "View and update" in table row for "Picture of funny meme"
    And I click link "Cancel request" in table row for "Picture of funny meme"
    Then I fill in "Explain to the applicant why this request is being cancelled" with "#{details}"
    And I see the cancel confirmation form actions
    And I press "Confirm cancellation"
    Then an email is sent to the applicant confirming the validation request cancellation
  )
end

Given("I cancel a(n) other change validation request with {string}") do |details|
  steps %(
    Given I create an other change validation request with "More info needed"
    And I click link "View and update" in table row for "Other"
    And I press "Cancel request"
    Then I fill in "Explain to the applicant why this request is being cancelled" with "#{details}"
    And I see the cancel confirmation form actions
    And I press "Confirm cancellation"
    Then an email is sent to the applicant confirming the validation request cancellation
  )
end

Given("I cancel a red line boundary change validation request with {string}") do |details|
  steps %(
    Given I create a red line boundary change validation request with "boundary change required"
    And I view the application's validations requests
    And I click link "View and update" in table row for "Red line boundary changes"
    And I press "Cancel request"
    Then I fill in "Explain to the applicant why this request is being cancelled" with "#{details}"
    And I see the cancel confirmation form actions
    And I press "Confirm cancellation"
    Then an email is sent to the applicant confirming the validation request cancellation
  )
end

Then("an email is sent to the applicant confirming the validation request cancellation") do
  body = ActionMailer::Base.deliveries.last.body.to_s
  expect(body).to include(@planning_application.secure_change_url)

  expect(body).to include(
    "We no longer need you to make a change to your application."
  )
end
