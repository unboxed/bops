# frozen_string_literal: true

require "faker"

Given("a determined planning application") do
  @planning_application.update!(status: "determined", determined_at: Time.zone.now)
end

Given("a rejected description change request") do
  FactoryBot.create(
    :description_change_validation_request,
    planning_application: @planning_application,
    state: "closed",
    approved: false,
    rejection_reason: "Spelling mistakes"
  )
end

Given("I create a description change request with {string}") do |details|
  steps %(
    I view the planning application
    And I press "Application information"
    And I press "Propose a change to the description"
    And I fill in "Please suggest a new application description" with "#{details}"
    And I press "Send"
  )
end

When("I visit the new description change request link") do
  visit new_planning_application_description_change_validation_request_path(@planning_application)
end

When("I cancel the existing description change request") do
  steps %(
    I view the planning application
    And I press "Application information"
    And I press "View requested change"
    When I press "Cancel this request"
  )
end

When("the description change request has been auto-closed after 5 days") do
  @planning_application.description_change_validation_requests.last.auto_approve!
end

When("the request has been responded to") do
  @planning_application.description_change_validation_requests.last.update!(state: "closed", approved: true)
end

When("the description request has been auto-closed") do
  @planning_application.description_change_validation_requests.last.update!(created_at: 6.business_days.ago)

  CloseDescriptionChangeJob.perform_now
end
