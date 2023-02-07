Feature: Adding policy assessment area to the application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And the planning application is validated

  Scenario: As an assessor I cannot assess an application if it hasn't been validated
    Given a new planning application
    When I view the planning application
    Then the page does not have a "Check and assess" link

  Scenario: As an assessor I can add classes to a validated application
    Given I add the policy classes "AA, B, F" to the application
    Then there is a row for the "Part 1, Class AA" policy with an "In progress" status
    And there is a row for the "Part 1, Class B" policy with an "In progress" status
    And there is a row for the "Part 1, Class F" policy with an "In progress" status

  Scenario: As an assessor I can remove classes from a validated application
    Given I add the policy class "AA" to the application
    And I remove the policy class "AA" from the application
    Then the page does not contain "Part 1, Class AA"
