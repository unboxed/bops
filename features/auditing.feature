Feature: Auditing a planning application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application

  Scenario: I can audit when a validation request is created
    Given I create a new document validation request for a "Picture of the dog" because "it would be nice"
    When I view the planning application audit
    Then there is an audit entry containing "Added: validation request (new document#1)"

  Scenario: I can audit the validation requests are sent when the application is invalid
    Given I create an additional document validation request with "Picture of the dog"
    And the planning application is invalidated
    When I view the planning application audit
    Then there is an audit entry containing "invalidation requests have been emailed: Additional document validation request #2, Additional document validation request #1"

  Scenario: I can audit when a validation request is cancelled after an application is made invalid
    Given I create an additional document validation request with "Meme of the dog"
    And the planning application is invalidated
    When I view the application's validations requests
    And I cancel a validation request for a "Meme of the dog" with "Meme of dog is no longer needed"
    When I view the planning application audit
    Then there is an audit entry containing "Cancelled: validation request (new document#1)"
    Then there is an audit entry containing "Reason: Meme of dog is no longer needed"

  Scenario: I can view in the audit log when a planning application has been withdrawn
    Given I press "Cancel application"
    And I choose "Withdrawn by applicant"
    And I fill in "Can you provide more detail?" with "Applicant is moving to Bermuda, because heck this"
    And I press "Save"
    Then there is an audit entry containing "Application withdrawn"
    Then there is an audit entry containing "Applicant is moving to Bermuda, because heck this"