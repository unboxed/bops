Feature: Managing validation requests
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application
    When I press "Validate application"
    And I press "Request validation changes"
    And I create a new document validation request for a "Picture of the dog" because "it would be nice"
    And I create a new document validation request for a "Picture of the cat" because "it would also be nice"
    And I create a red line boundary change validation request with "Need this red line"

  Scenario Outline: As an assessor I can create different validation requests
    When I create a <type> validation request with "<comment>"
    Then there is a validation request for a "<comment>" that shows "Not sent"
    Examples:
      | type                     | comment                         |
      | additional document      | John                            |
      | other change             | George                          |

  Scenario: As an assessor all my validation requests are initially not sent
    When I view the application's validations requests
    Then there is a validation request for a "Picture of the dog" that shows "Not sent"
    Then there is a validation request for a "Picture of the cat" that shows "Not sent"
    And there is a validation request for a "View proposed red line boundary" that shows "Not sent"

  Scenario: As an assessor I can see the time left on each request of an invalidated application
    When I press "Mark the application as invalid"
    And I view the application's validations requests
    Then there is a validation request for a "Picture of the dog" that shows "15 days"
    Then there is a validation request for a "Picture of the cat" that shows "15 days"
    And there is an audit entry containing "The following invalidation requests have been emailed: Red line boundary change validation request #1, Additional document validation request #2"

  Scenario: As an assessor any request past invalidation is sent immediately
    Given the planning application is invalidated
    When I create an other change validation request with "Extra request"
    Then there is a validation request for an "Extra request" that shows "15 days"
    And there is an audit entry containing "Sent: validation request (other validation#1)"

  Scenario: As an assessor I can delete a validation request before invalidating the planning application
    When I view the application's validations requests
    Then there is a validation request for a "Picture of the dog" that has a link "Delete request"
    And there is a validation request for a "Picture of the dog" that does not have a link "Cancel request"
    When I click link "Delete request" in table row for "Picture of the dog"
    And I view the application's validations requests
    Then there is no validation request for a "Picture of the dog"

  Scenario: As an assessor I can cancel a validation request only after invalidating the planning application
    Given the date is 21-10-2021
    And the planning application is invalidated
    When I view the application's validations requests
    Then there is a validation request for a "Picture of the dog" that has a link "Cancel request"
    And there is a validation request for a "Picture of the dog" that does not have a link "Delete request"
    When I cancel a validation request for a "Picture of the dog" with "Dog pic is no longer needed"
    And I view the application's validations requests
    Then there is a cancelled validation request for a "Dog pic is no longer needed" that shows "21 October 2021"
    And there is no validation request for a "Picture of the dog"
    And there is an audit entry containing "Cancelled: validation request (new document#1)"

  Scenario Outline: As an assessor I can cancel different validation requests
    Given the date is 21-10-2021
    And the planning application is invalidated
    When I cancel a <type> validation request with "<reason>"
    Then there is a cancelled validation request for a "<reason>" that shows "21 October 2021"
    Examples:
      | type                     | reason                        |
      | additional document      | document no longer needed     |
      | other change             | my mistake                    |
      | red line boundary change | original boundary was correct |
