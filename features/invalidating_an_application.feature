Feature: Invalidating application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application

  Scenario: As an assessor I can invalidate new applications
    Then the page has a "Check and validate" link

  Scenario: As an assessor I can invalidate an application with validation requests
    When I press "Check and validate"
    And I press "Send validation decision"
    And I create a new document validation request for a "Picture of the dog" because "it would be nice"
    And I press "Back"
    And I press "Send validation decision"
    When I press "Mark the application as invalid"
    Then the page contains "Application has been invalidated"
