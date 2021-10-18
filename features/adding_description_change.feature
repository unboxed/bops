Feature: Creating a description change on the application as an assessor
  Background:
    Given I am logged in as an assessor
    And a new planning application with a description of "Add a statue of Melissa striking poses"

  Scenario: I can add a new description change request
    Given I create a description change request with "Add a backyard cinema"
    Then the page contains "Description change request successfully sent."
    
  Scenario: I can view the description change request
    When I click on "Application information"
    And I click on "View requested change"
    Then the page contains "Previous description"
    Then the page contains "Add a statue of Melissa striking poses"
    Then the page contains "Proposed description"
    Then the page contains "Add a backyard cinema"

  Scenario: I cannot create a second description change request if an open one exists
    Given I create a description change request with "A backyard full of burritos"
    When I visit the new description change request link

  Scenario: I can cancel a description change request
    Given an existing description change request
    When I view the planning application with description
    And I click on "Application information"
    And I click on "View requested change"
    And I click on "Cancel this request"
    Then the page contains "Description change request successfully cancelled"

  Scenario: When a previous change request has been rejected
    Given a rejected description change request
    When I click on "Application information"
    And I click on "Propose a change to the description"
   Then the page contains "Rejected proposed description"