Feature: Invalidating application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application

  Scenario: As an assessor I can invalidate new applications
    Then the page has a "Check and validate" link
