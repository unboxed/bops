Feature: Editing an application's constraints
  Background:
    Given I am logged in as an assessor
    And a validated planning application
    And the planning application has the "Conservation area" constraint
    And I view the planning application

  Scenario: As an assessor I cannot add constraints past determination
    Given a recommendation is submitted for the planning application
    When I press "Check and assess"
    And I press "Constraints"
    Then the page does not contain "Update constraints"
