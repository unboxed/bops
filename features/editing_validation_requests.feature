Feature: Editing validation requests
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application
    When I press "Validate application"
    And I press "Request validation changes"
    And I create a new document validation request for a "Picture of the dog" because "it would be nice"
    And I create a new document validation request for a "Picture of the cat" because "it would also be nice"

Scenario: I can edit a document validation request before its been sent
  When I view the application's validations requests
  And I press "Edit" on "Picture of the dog"
  And fill in "Reason for requesting this document" with "cats instead"
  When I press "Update"
  And I view all validation requests
  Then the table contains "cats instead"

Scenario: I cannot edit a document validation request after its been sent
  When I view the application's validations requests
  And the planning application is invalidated
  Then there is no "Edit" option in the validation requests table
