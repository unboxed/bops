# frozen_string_literal: true

require "faker"

Given("a new planning application with a description of #{description}") do
  @planning_application_with_description = FactoryBot.create(
    :planning_application,
    :not_started,
    description: description,
    local_authority: @officer.local_authority
  )
end

When("I visit the new description change request link") do
  visit new_description_change_validation_requests_path(@planning_application)
end

When("I view the planning application with description") do
  visit planning_application_path(@planning_application_with_description)
end