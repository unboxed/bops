Feature: Editing an application's constraints
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And the planning application has the "Conservation Area" constraint
    And I view the planning application

  Scenario: As an assessor I can view the existing constraints on the application
    Given I press "Constraints"
    Then the page contains "Conservation Area"

  Scenario: As an assessor I can view the existing constraints on the edit form
    Given I visit the application's constraints form
    Then the "Conservation Area" option is checked

  Scenario: As an assessor I can edit the application constraints
    Given I visit the application's constraints form
    And I check "Safeguarded land"
    When I press "Save"
    And I visit the application's constraints form
    Then the "Safeguarded land" option is checked
    And there is an audit entry containing "Constraint added"

  Scenario: As an assessor I can add custom constraints to the application
    Given I visit the application's constraints form
    And I fill in "Add a local constraint" with "Batcave"
    And I press "Save"
    When I visit the application's constraints form
    Then the "Batcave" option is checked

  Scenario: As an assessor I cannot add constraints past determination
    Given a recommendation is submitted for the planning application
    When I press "Constraints"
    Then the page does not contain "Update constraints"
