Feature: Adding a note
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And I view the planning application
    And the time is 14:00 on the 5-11-2021

Scenario Outline: As an assessor I can add notes
  When I press "Add a note"
  Then I see that there are no notes
  When I add a note with "This is an epic note"
  Then I see the current note with entry "This is an epic note" at "5 November 2021"
  When I press "Add and view all notes"
  Then I see that there is one note
  And I see that there is a note with entry "This is an epic note" at "5 November 2021 14:00"
  When the time is 15:25 on the 5-11-2021
  And I add a note with "This is another epic note"
  And I view the planning application notes
  Then I see that there are multiple notes
  And I see that there is a note with entry "This is another epic note" at "5 November 2021 15:25"
  When I view the planning application
  Then I see the current note with entry "This is another epic note" at "5 November 2021"
