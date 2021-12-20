Feature: Uploading documents for an application
  Background:
    Given I am logged in as an assessor
    And my name is "Morisuke"
    And a new planning application
    When I manage the documents for the application

  Scenario: I can upload a new document with a reference, received date and tags
    Given I press "Upload document"
    And I upload "spec/fixtures/images/proposed-floorplan.png" for the "file" input
    And I set the date inputs to "5/7/2021"
    And I check "Floor"
    And I check "Side"
    And I check "Utility Bill"
    And I choose "Yes" for "Do you want to list this document on the decision notice?"
    And I choose "Yes" for "Should this document be made publicly available?"
    And I fill in "Document reference(s)" with "Floorplan"
    And I press "Save"
    Then the page contains "proposed-floorplan.png has been uploaded."
    And the page contains "Date received: 5 July 2021"
    And the page contains "Included in decision notice: Yes"
    And the page contains "Public: Yes"
    When I view the document with reference "Floorplan"
    Then the page contains "This document was manually uploaded by Morisuke"
    And the option "Floor" is checked
    And the option "Side" is checked
    And the option "Utility Bill" is checked

 Scenario: I can upload a new document with no tags and it defaults to not public
    Given I press "Upload document"
    And I upload "spec/fixtures/images/proposed-floorplan.png" for the "file" input
    And I press "Save"
    Then the page contains "proposed-floorplan.png has been uploaded."
    Then the page contains "Included in decision notice: No"
    Then the page contains "Public: No"