Feature: Managing validation requests
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application
    When I press "Validate application"
    And I press "Request validation changes"
    And I create a new document validation request for a "Picture of the dog" because "it would be nice"
    And I create a new document validation request for a "Picture of the cat" because "it would also be nice"

  Scenario: As an assessor all my validation requests are initially not sent
    # this first step isn't necessary but story-telling is important
    When I view the application's validations requests
    Then there is a new document request for a "Picture of the dog" that shows "Not sent"
    Then there is a new document request for a "Picture of the cat" that shows "Not sent"

  Scenario: As an assessor I can see the time left on each request of an invalidated application
    When I press "Invalidate"
    And I view the application's validations requests
    Then there is a new document request for a "Picture of the dog" that shows "15 days"
    Then there is a new document request for a "Picture of the cat" that shows "15 days"
