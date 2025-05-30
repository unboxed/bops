Feature: Creating a description change on the application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And the planning application has a description of "Add a statue of Melissa striking poses"
    And I view the planning application

  Scenario: I can add a new description change request
    Given I create a description change request with "Add a backyard cinema"
    Then the page contains "Description change request successfully sent."

  Scenario: I can cancel a description change request
    Given I create a description change request with "Add a backyard cinema"
    And I cancel the existing description change request
    Then the page contains "Description change request successfully cancelled"
    And there is an audit entry containing "Cancelled: validation request"

  Scenario: I can add and view a new description change request after cancelling the previous one
    Given I create a description change request with "Its margarita time ole!"
    And I press "Check description"
    Then the page contains "Previous description"
    Then the page contains "Add a statue of Melissa striking poses"
    Then the page contains "Proposed description"
    Then the page contains "Its margarita time ole!"

  Scenario: When a change request has been rejected I can view it when creating a new one
    Given a rejected description change request
    And I press "Check and validate"
    And I press "Check description"
    Then the page contains "Rejected"

  Scenario: I cannot create a second description change request when an open one exists
    Given I create a description change request with "A yard full of bananas"
    When I visit the new description change request link
    And I fill in "Enter an amended description to send to the applicant" with "Mambo number 2"
    And I press "Send"
    Then the page contains "An open description change already exists for this planning application."

  Scenario: I can view a notification banner when a request has been auto-closed
    Given I create a description change request with "Add a rooftop cinema"
    And the description change request has been auto-closed after 5 days
    When I view the planning application
    Then the page contains "Description change request has been automatically accepted after 5 days."

  Scenario: I can view a notification banner when a request has been responded to
    Given I create a description change request with "Add a golden fence"
    And the request has been responded to
    When I view the planning application
    Then the page contains "new response to a validation request"

  Scenario: After a request auto-closed I can see an updated planning application description
    Given I create a description change request with "Add a ball pit"
    When the description request has been auto-closed
    And I view the planning application
    Then the page contains "Add a ball pit"
    And there is an audit entry containing "Auto-closed: validation request (description#1)"
