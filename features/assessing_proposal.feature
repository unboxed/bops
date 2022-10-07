Feature: Assessing a proposal
  Background: 
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application
    And the planning application is validated

Scenario: I can save a draft assessment on the planning application
    Given I press "Assess recommendation"
    When I fill in "State the reasons why this application is, or is not lawful." with "Lawful as can be"
    And I fill in "Please provide supporting information for your manager." with "I'm hoping you feel supported"
    And I press "Save and come back later"
    When I view the planning application
    Then the assess proposal accordion displays a "In progress" tag
    When I press "Assess recommendation"
    Then the page contains "Lawful as can be"
    And the page contains "I'm hoping you feel supported"

Scenario: I can submit an assessment on the planning application
    Given I press "Assess recommendation"
    When I choose "Yes"
    And I fill in "State the reasons why this application is, or is not lawful." with "Lawful as can be"
    And I fill in "Please provide supporting information for your manager." with "I'm hoping you feel supported"
    And I press "Save and mark as complete"
    Then the assess proposal accordion displays a "Complete" tag
