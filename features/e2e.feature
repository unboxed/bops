@e2e @javascript
Feature: End-to-end integration
  Scenario: it works properly
    Given I am logged in as an assessor
    And a new planning application
    And I create a description change validation request with "Making my house nice"
    And the planning application is invalidated
    And I switch to BOPS-applicants
    And I look at the validation requests on my application
    And I press "Description"
    And I choose "Yes, I agree with the changes made"
    And I press "Submit"
    Then the page contains "Change request successfully updated"
    When I switch to BOPS
    And I view the application's validations requests
    Then there is a validation request for a "Making my house nice" that shows "Accepted"
