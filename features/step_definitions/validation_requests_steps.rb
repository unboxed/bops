# frozen_string_literal: true

When("I view the application's validations requests") do
  visit planning_application_validation_requests_path(@planning_application)
end

When("I create a new document validation request for a(n) {string} because {string}") do |type, reason|
  steps %(
    Given I view the application's validations requests
    Then the page contains "Add new request"
    And I press "Add new request"
    And I choose "Request a new document"
    And I press "Next"
    And I fill in "Please specify the new document type:" with "#{type}"
    And I fill in "the reason" with "#{reason}"
    And I press "Send"
  )
end

Then("there is a new document request for a(n) {string} that shows {string}") do |request_details, status|
  table = page.find(:table, "Validation requests")

  expect(table).to have_selector(:table_row, "Detail" => request_details, "Status" => status)
end
