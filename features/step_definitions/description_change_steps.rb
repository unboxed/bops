# frozen_string_literal: true

require "faker"

Given("a new planning application with a description of {string}") do |string|
  @planning_application_with_description = FactoryBot.create(
    :planning_application,
    :not_started,
    description: string,
    local_authority: @officer.local_authority
  )
end

Given("an existing description change request") do
  @description_change_request = FactoryBot.create(
    :description_change_validation_request,
    planning_application: @planning_application_with_description
  )
end

Given("a determined planning application") do
  @determined_planning_application = FactoryBot.create(
    :planning_application,
    :determined,
    local_authority: @officer.local_authority
  )
end

Given("a rejected description change request") do
  @rejected_description_change = FactoryBot.create(
    :description_change_validation_request,
    planning_application: @planning_application_with_description,
    state: "closed",
    approved: false,
    rejection_reason: "Spelling mistakes"
  )
end

Given("I create a description change request from the application index with {string}") do |details|
  steps %(
    I view the planning application with description
    And I press "Application information"
    And I press "Propose a change to the description"
    And I fill in "Please suggest a new application description" with "#{details}"
    And I press "Add"
  )
end

Given("I create a description change request from the application edit page with {string}") do |details|
  steps %(
    I view the planning application with description
    And I press "Application information"
    And I press "Edit details"
    And I press "Propose a change to the description"
    And I fill in "Please suggest a new application description" with "#{details}"
    And I press "Add"
  )
end

When("I visit the new description change request link") do
  visit new_planning_application_description_change_validation_request_path(@planning_application_with_description)
end

When("I view the planning application with description") do
  visit planning_application_path(@planning_application_with_description)
end

When("I view the determined application") do
  visit planning_application_path(@determined_planning_application)
end

And("I click on Application information") do
  label = find("#application-information")
  click_on label
end
