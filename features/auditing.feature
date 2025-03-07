Feature: Auditing a planning application
  Background:
    Given I am logged in as an assessor
    And my name is "Miyazaki"
    And a new planning application
    And I view the planning application

  Scenario: I can audit when a validation request is created
    Given I create a new document validation request for a "Picture of the dog" because "it would be nice"
    When I view the planning application audit
    Then there is an audit entry containing "Added: validation request (new document#1)"
    And there is an audit log entry in the index accordion with "Added: validation request (new document#1)"

  Scenario: I can audit the validation requests are sent when the application is invalid
    Given I create an additional document validation request with "Picture of the dog"
    And the planning application is invalidated
    When I view the planning application audit
    Then there is an audit entry containing "invalidation requests have been emailed: Additional document validation request #1, Additional document validation request #2"
    And there is an audit entry containing "Application invalidated"

  Scenario: I can audit when a validation request is cancelled after an application is made invalid
    Given I create an additional document validation request with "Meme of the dog"
    And the planning application is invalidated
    When I view the application's validations requests
    And I cancel a validation request for a "Meme of the dog" with "Meme of dog is no longer needed"
    When I view the planning application audit
    Then there is an audit entry containing "Cancelled: validation request (new document#1)"
    Then there is an audit entry containing "Reason: Meme of dog is no longer needed"

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
