Feature: Editing validation requests
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application
    When I press "Validate application"
    And I press "Start now"
    And I press "Send validation decision"
    And I create a new document validation request for a "Picture of the dog" because "it would be nice"
    And I create a other change validation request with "Time for some changes up in here"
    And I create a red line boundary change validation request with "We shall update some boundaries"

Scenario: I can edit a document validation request before its been sent
  When I view the application's validations requests
  And I click link "Edit" in table row for "Picture of the dog"
  And I fill in "Please specify the new document type:" with "cats instead"
  And I fill in "Please specify the reason you have requested this document?" with "I love me some cats"
  When I press "Update"
  And I view the application's validations requests
  Then the page contains "cats instead"
  And the page contains "I love me some cats"

Scenario: I can edit an other type of validation request before its been sent
  When I view the application's validations requests
  And I click link "Edit" in table row for "Time for some changes"
  And I fill in "Tell the applicant another reason why the application is invalid." with "change those manners"
  When I press "Update"
  And I view the application's validations requests
  Then the page contains "change those manners"

Scenario: I can edit a red line boundary request before its been sent
  When I view the application's validations requests
  And I click link "Edit" in table row for "We shall update some boundaries"
  And I fill in "Explain to the applicant why changes are proposed to the red line boundary" with "bound to be changes"
  When I press "Update"
  And I view the application's validations requests
  Then the page contains "bound to be changes"

Scenario: I cannot edit a validation request after its been sent
  When the planning application is invalidated
  And I view the application's validations requests
  Then the page does not contain "Edit" in table row for "Picture of the dog"
  And the page does not contain "Edit" in table row for "Time for some changes"
  And the page does not contain "Edit" in table row for "We shall update some boundaries"
