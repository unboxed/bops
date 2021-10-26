Feature: Invalidating application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application

  Scenario: As an assessor I can invalidate new applications
    Then the page has a "Validate application" link

  Scenario: As an assessor I cannot invalidate an application without validation requests
    When I press "Validate application"
    And I press "Request validation changes"
    When I press "Invalidate"
    Then the page contains a custom flash about "Please create at least one validation request before invalidating"

  Scenario: As an assessor I can invalidate an application with validation requests
    When I press "Validate application"
    And I press "Request validation changes"
    And I create a new document validation request for a "Picture of the dog" because "it would be nice"
    When I press "Invalidate"
    Then the page contains "Application has been invalidated"
