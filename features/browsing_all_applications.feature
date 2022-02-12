Feature: As an assessor I can browse all applications
  Background:
    Given I am logged in as an assessor
    And a new planning application

  Scenario Outline: I can see a colour-coded expiry date
    Given the time is 10:00
    And the application expires in <days> days
    When I view all "Not started" planning applications
    Then the page contains a "<colour>" tag containing "<days> days"
    Examples:
      | days | colour |
      |   12 | green  |
      |    7 | yellow |
      |    2 | red    |

  Scenario: I can see how many days is the application overdue during the working week
    Given the date is 11-02-2022
    And the application expired 10 days ago
    When I view all "Not started" planning applications
    Then the page contains a "red" tag containing "10 days overdue"

  Scenario: I can see how many days is the application overdue during the weekend
    Given the date is 12-02-2022
    And the application expired 10 days ago
    When I view all "Not started" planning applications
    Then the page contains a "red" tag containing "10 days overdue"
