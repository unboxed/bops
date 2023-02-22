Feature: Assessing a proposal
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application
    And the planning application is validated

Scenario: I can save a draft assessment on the planning application
    Given I press "Check and assess"
    And I press "Make draft recommendation"
    When I fill in "State the reasons why this application is, or is not lawful." with "Lawful as can be"
    And I fill in "Provide support information for your manager." with "I'm hoping you feel supported"
    And I press "Save and come back later"
    When I view the planning application
    When I press "Check and assess"
    Then the complete assessment accordion displays a "In progress" tag
    And I press "Make draft recommendation"
    Then the page contains "Lawful as can be"
    And the page contains "I'm hoping you feel supported"

Scenario: I can submit an assessment on the planning application
    When I press "Check and assess"
    And I press "Make draft recommendation"
    When I choose "Yes"
    And I fill in "State the reasons why this application is, or is not lawful." with "Lawful as can be"
    And I fill in "Provide support information for your manager." with "I'm hoping you feel supported"
    And I press "Save and mark as complete"
    Then the complete assessment accordion displays a "Complete" tag
