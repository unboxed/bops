# frozen_string_literal: true

Then("there is an audit entry containing {string}") do |content|
  step "I visit the audit log"

  within_table("Audit log") do
    expect(page).to have_content content
  end
end

When("I click on the audit accordion") do
  page.find("#audit-log").click
end

When("I visit the audit log") do
  steps %(
    When I view the planning application
    Then I click on the audit accordion
    Then I press "View all"
  )
end
