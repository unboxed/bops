# frozen_string_literal: true

When("I view the application's validations requests") do
  visit planning_application_validation_requests_path(@planning_application)
end

When("I create a new document validation request for a {string} because {string}") do |type, reason|
  steps %(I view the application's validation requests)

  click_on  "Add new request"
  choose "Request a new document"

  click_on "Next"

  fill_in "Please specify the new document type:", with: type
  fill_in "the reason", with: reason

  click_on "Send"
end

Then("there is a new document request for a {string} that shows {string}") do |request_details, status|
  table = page.find(:table, "Validation requests")

  expect(table).to have_selector(:table_row, "Detail" => request_details, "Status" => status)
end
