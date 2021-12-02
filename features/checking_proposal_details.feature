Feature: Checking proposal details are visible in the planning application
  Background:
    Given I am logged in as an assessor
    And a new application of type prior approval

  Scenario: I can view the correct flags have been assigned to the planning application
    When I view the planning application
    Then there is a relevant proposal detail for "The height of the new roof will be higher than the old roof by" with a response of "7m or less"
    And there is a relevant proposal detail for "I will add" with a response of "1-2 new storeys"
    And there is a relevant proposal detail for "The new storeys will be" with a response of "on the principal part of the building only"
