Feature: Checking proposal details are visible in the planning application
  Background:
    Given I am logged in as an assessor
    And a new application of type prior approval
    And I view the planning application

Scenario: I can view the correct flags have been assigned to the planning application
  Then the page contains "Planning permission / Prior approval"
  And the page contains "Details identified as relevant to the result"
  And the page contains "I will add"
  And the page contains "1-2 new storeys"
  And the page contains "The height of the new roof will be higher than the old roof by"
  And the page contains "7m or less"
