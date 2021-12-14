# frozen_string_literal: true

Given("the planning application has the {string} constraint") do |constraint|
  @planning_application.constraints << constraint

  @planning_application.save!
end

Given("I visit the application's constraints form") do
  steps %(
    Given I view the planning application
    And I press "Constraints"
    And I press "Update constraints"
  )
end
