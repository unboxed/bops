# frozen_string_literal: true

Then("there is an audit entry containing {string}") do |content|
  step "I visit the audit log"

  within_table("Activity log") do
    expect(page).to have_content content
  end
end

When("I visit the audit log") do
  steps %(
    When I view the planning application
    Then I press "Key application dates"
    Then I press "Activity log"
  )
end
