# frozen_string_literal: true

Then("there is an audit entry containing {string}") do |content|
  step "I visit the audit log"

  within_table("Audit log") do
    expect(page).to have_content(content, normalize_ws: true)
  end
end

Then("there is not an audit entry containing {string}") do |content|
  step "I visit the audit log"

  within_table("Audit log") do
    expect(page).not_to have_content(content, normalize_ws: true)
  end
end

Then("there is an audit entry with") do |content|
  step "I visit the audit log"

  within_table("Audit log") do
    page.should have_content(content)
  end
end

Then("there is an audit log entry in the index accordion with {string}") do |content|
  steps %(
    When I view the planning application
    And I press "Audit log"
    Then the page contains "#{content}"
  )
end

When("I visit the audit log") do
  steps %(
    When I view the planning application
    Then I press "Audit log"
    Then I press "View all audits"
  )
end
