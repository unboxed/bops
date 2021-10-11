Feature: Auditing a planning application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application

  Scenario: As an assessor I can audit when a validation request is created
    Given I create a new document validation request for a "Picture of the dog" because "it would be nice"
    When I view the planning application audit
    Then there is an audit entry containing "Added: validation request (new document#1)"
