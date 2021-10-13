# frozen_string_literal: true

When("I view the application's validations requests") do
  visit planning_application_validation_requests_path(@planning_application)
end

When("I create a new document validation request for a(n) {string} because {string}") do |type, reason|
  steps %(
    Given I view the application's validations requests
    And I press "Add new request"
    And I choose "Request a new document"
    And I press "Next"
    And I fill in "Please specify the new document type:" with "#{type}"
    And I fill in "the reason" with "#{reason}"
    And I press "Add"
  )
end

Then("there is a validation request for a(n) {string} that shows {string}") do |request_details, status|
  table = page.find(:table, "Validation requests")

  expect(table).to have_selector(:table_row, "Detail" => request_details, "Status" => status)
end

Given("I add a new validation request") do
  steps %(
    Given I view the application's validations requests
    And I press "Add new request"
  )
end

Given("I create a(n) additional document validation request with {string}") do |details|
  steps %(
    Given I add a new validation request
    And I choose "Request a new document"
    And I press "Next"
    And I fill in "Please specify the new document type:" with "#{details}"
    And I fill in "the reason" with "a valid reason"
    And I press "Add"
  )
end

Given("I create a description change validation request with {string}") do |details|
  steps %(
    Given I add a new validation request
    And I choose "Request approval to a description change"
    And I press "Next"
    And I fill in "Please suggest a new application description" with "#{details}"
    And I press "Add"
  )
end

Given("I create a(n) other change validation request with {string}") do |details|
  steps %(
    Given I add a new validation request
    And I choose "Request other change to application"
    And I press "Next"
    And I fill in "Tell the applicant" with "#{details}"
    And I fill in "Explain to the applicant" with "Please make the change"
    And I press "Add"
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
