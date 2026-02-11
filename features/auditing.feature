Feature: Auditing a planning application
  Background:
    Given I am logged in as an assessor
    And my name is "Miyazaki"
    And a new planning application
    And I view the planning application

  Scenario: I can view in the audit log when a planning application has been withdrawn
    Given the application is withdrawn by the applicant
    Then there is an audit entry containing "Application withdrawn"
    And there is an audit entry containing "Applicant is moving to Bermuda, because heck this"

  Scenario: I can view in the audit log when a planning application has been returned
    Given the application is returned by the applicant
    Then there is an audit entry containing "Application returned"
    And there is an audit entry containing "Applicant sent selfies instead of floor plans"

  Scenario: I can view an entry in the audit log showing application updates
    And I click "Application information"
    When I press "Edit details"
    And I fill in "Address 1" with "20 leafy gardens"
    And I fill in "Payment reference" with " "
    And I press "Save"
    Then there is an audit entry containing "Address 1 updated"
    And there is an audit entry containing "Miyazaki"
    And there is an audit entry containing "Changed to: 20 leafy gardens"
    And there is not an audit entry containing "Payment reference updated"

  Scenario: I can view an entry in the audit showing the application being validated
    When I press "Check and validate"
    And I press "Send validation decision"
    And I press "Mark the application as valid"
    And I press "Mark the application as valid"
    Then there is an audit entry containing "Application validated"
