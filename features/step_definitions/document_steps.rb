# frozen_string_literal: true

Given("I manage the application's documents") do
  steps %(
    Given I view the planning application
    And I press "Manage documents"
  )
end

Given("the planning application has a document with reference {string}") do |reference|
  steps %(
    When I manage the application's documents
    And I press "Upload document"
    And I upload "spec/fixtures/images/proposed-floorplan.png" for the "file" input
    And I fill in "Document reference(s)" with "#{reference}"
    And I press "Save"
  )
end

Given("I view the document with reference {string}") do |reference|
  step "I manage the application's documents"

  document = @planning_application.documents.find_by(numbers: reference)

  visit edit_planning_application_document_path(@planning_application, document)
end

Given("I attach a replacement file with path {string}") do |path|
  step %(I upload "#{path}" for the "file" input)
end

Given("I set the date inputs to {string}") do |date|
  day, month, year = date.split("/")

  steps %(
    Given I fill in "Day" with "#{day}"
    And I fill in "Month" with "#{month}"
    And I fill in "Year" with "#{year}"
  )
end
