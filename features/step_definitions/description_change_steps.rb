# frozen_string_literal: true

require "faker"

Given("a rejected description change request") do
  FactoryBot.create(
    :description_change_validation_request,
    planning_application: @planning_application,
    state: "closed",
    applicant_approved: false,
    applicant_rejection_reason: "Spelling mistakes"
  )
end

Given("I create a description change request with {string}") do |details|
  steps %(
    When I view the planning application
    And I press "Check and validate"
    And I press "Application information"
    And I press "Propose a change to the description"
    And I fill in "Please suggest a new application description" with "#{details}"
    And I press "Send"
  )
end

When("I visit the new description change request link") do
  visit "/planning_applications/#{@planning_application.id}/validation/validation_requests/new?type=description_change"
end

When("I cancel the existing description change request") do
  steps %(
    When I view the planning application
    And I press "Check and validate"
    And I press "Application information"
    And I press "View requested change"
    When I press "Cancel this request"
  )
end

When("the description change request has been auto-closed after 5 days") do
  @planning_application.validation_requests.description_changes.last.auto_close_request!
end

When("the request has been responded to") do
  @planning_application.validation_requests.description_changes.last.update!(state: "closed", applicant_approved: true)
end

When("the description request has been auto-closed") do
  @planning_application.validation_requests.description_changes.last.update!(created_at: 6.business_days.ago)

  CloseDescriptionChangeJob.perform_now
end
