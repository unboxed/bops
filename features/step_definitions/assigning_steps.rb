# frozen_string_literal: true

Given("a fellow assessor called {string}") do |name|
  FactoryBot.create(
    :user,
    :assessor,
    local_authority: @officer.local_authority,
    name: name
  )
end

Given("I assign the application to {string}") do |name|
  within(".assignment_cta") do
    step 'I press "Change"'
  end

  steps %(
    And I choose "#{name}"
    And I press "Confirm"
  )
end

Given("I unassign the application") do
  step 'I assign the application to "Unassigned"'
end
