Feature: Editing an application's details
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I edit the planning application's details

  Scenario: I can edit the application's received date
    Given I fill in "Day" with "3"
    And I fill in "Month" with "10"
    And I fill in "Year" with "1989"
    When I press "Save"
    And I press "Application"
    Then the page contains "Target date: 7 November 1989"

  Scenario: I can edit the applicaiton's site details
    Given I fill in "Address 1" with "2 Streatham High Road"
    And I fill in "Address 2" with "Streatham"
    And I fill in "Town" with "Crystal Palace"
    And I fill in "County" with "London"
    And I fill in "Postcode" with "SW16 1DB"
    And I fill in "UPRN" with "294884040"
    When I press "Save"
    Then the page contains "2 Streatham High Road, Crystal Palace, SW16 1DB"
    And there is an audit entry containing "Address 1 updated"
    And there is an audit entry containing "Changed to: 2 Streatham High Road"

  Scenario: I can edit the application's proposed or completed status
    Given I choose "Yes" for "Has the work been started?"
    When I press "Save"
    Then the page contains "Work already started: Yes"

  Scenario: I can edit the application's applicant details
    Given I am focused on the "Applicant information" fieldset
    And I fill in "First name" with "Pearly"
    And I fill in "Last name" with "Poorly"
    And I fill in "Email address" with "pearly@poorly.com"
    And I fill in "UK telephone number" with "0777773949494312"
    When I press "Save"
    And I press "Application"
    Then the page contains "Pearly Poorly"
    And the page contains "pearly@poorly.com"
    And the page contains "0777773949494312"

  Scenario: I can edit the agent's details
    Given I am focused on the "Agent information" fieldset
    And I fill in "First name" with "Pearly"
    And I fill in "Last name" with "Poorly"
    And I fill in "Email address" with "pearly@poorly.com"
    And I fill in "UK telephone number" with "0777773949494312"
    When I press "Save"
    And I press "Application"
    Then the page contains "Pearly Poorly"
    And the page contains "pearly@poorly.com"
    And the page contains "0777773949494312"

  Scenario: I can edit the payment's reference
    Given I fill in "Payment reference" with "293844848"
    When I press "Save"
    Then the page contains "293844848"

  Scenario: I cannot edit a planning application if it has an assessment in progress
    Given a draft assessment on the planning application
    When I edit the planning application's details
    And I fill in "Address 2" with "Happy Buns"
    And I press "Save"
    Then the page contains "Please complete in draft assessment before updating application fields."
