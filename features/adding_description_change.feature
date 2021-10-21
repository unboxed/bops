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
    Given I cancel the existing description change request
    Then the page contains "Description change request successfully cancelled"
    And there is an audit entry containing "Cancelled: description change request"
  
  Scenario: I can add and view a new description change request after cancelling the previous one
    Given I create a description change request with "Its margarita time ole!"
    When I press "Application information"
    And I press "View requested change"
    Then the page contains "Previous description"
    Then the page contains "Add a statue of Melissa striking poses"
    Then the page contains "Proposed description"
    Then the page contains "Its margarita time ole!"
  
  Scenario: When a change request has been rejected I can view it when creating a new one
    Given a rejected description change request
    When I press "Application information"
    And I press "Propose a change to the description"
    Then the page contains "Rejected proposed description"

  Scenario: I cannot create a second description change request when an open one exists
    Given I create a description change request with "A yard full of bananas"
    When I visit the new description change request link
    And I fill in "Please suggest a new application description" with "Mambo number 2"
    And I press "Add"
    Then the page contains "An open description change already exists for this planning application."

  Scenario: I cannot create a description change request on a determined planning application
    Given a determined planning application
    When I view the determined application
    When I press "Application information"
    And I press "Propose a change to the description"
    And I fill in "Please suggest a new application description" with "Mambo number 10"
    And I press "Add"
    Then the page contains "A description change request cannot be submitted for a determined planning application"
