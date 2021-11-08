Feature: As an assessor I can browse all applications
  Background:
    Given I am logged in as an assessor
    And a new planning application

  Scenario Outline: I can see a colour-coded expiry date
    Given the application expires in <days> days
    When I view all "Not started" planning applications
    Then the page contains a "<colour>" tag containing "<days> days"
    Examples:
      | days | colour |
      |   12 | green  |
      |    7 | yellow |
      |  -10 | red    |
