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

Given("a rejected description change request") do
  @rejected_description_change = FactoryBot.create(
    :description_change_validation_request,
    planning_application: @planning_application_with_description,
    state: "closed",
    approved: false,
    rejection_reason: "Spelling mistakes"
  )
end

When("I visit the new description change request link") do
  visit new_description_change_validation_requests_path(@planning_application_with_description)
end

When("I view the planning application with description") do
  visit planning_application_path(@planning_application_with_description)
end
