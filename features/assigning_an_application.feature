Feature: Assigning an application
  Background:
    Given I am logged in as an assessor
    And a fellow assessor called "John Lemon"
    And a new planning application
    And I view the planning application

  Scenario: I can assign to another user
    Given I assign the application to "John Lemon"
    When I view the planning application
    Then the page contains "Assigned to: John Lemon"
    And there is an audit entry containing "Application assigned to John Lemon"

  Scenario: I can unassign the application
    Given I assign the application to "John Lemon"
    And I unassign the application
    When I view the planning application
    Then the page contains "Unassigned"
    And there is an audit entry containing "Application unassigned"
