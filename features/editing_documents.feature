Feature: Editing documents for an application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And the planning application has a document with reference "FOOBAR"
    And I view the planning application
    And I view the document with reference "FOOBAR"

  Scenario: I can replace the document
    Given I attach a replacement file with path "spec/fixtures/images/proposed-roofplan.pdf"
    And I fill in "Document reference(s)" with "DOC0001"
    And I check "Floor"
    And I check "Side"
    And I choose "Yes" for "Do you want to list this document on the decision notice?"
    And I choose "Yes" for "Should this document be made publicly available?"
    When I press "Save"
    Then the page contains "Document has been updated"
    And the page contains "DOC0001"
    And the page contains "Included in decision notice: Yes"
    And the page contains "Public: Yes"

  Scenario: I can edit the document's received at date
    Given I set the date inputs to "19/11/2021"
    When I press "Save"
    Then the page contains "Date received: 19 November 2021"
    And there is an audit entry containing "received at date was modified"

  Scenario: I can mark a document as not valid
    Given I choose "No" for "Is the document valid?"
    And I fill in "Describe in full why the document is invalid." with "BANANAS"
    When I press "Save"
    Then the page contains "Invalid documents: 1"
    Then the page contains "BANANAS"
    And there is an audit entry containing "proposed-floorplan.png was marked as invalid"

  Scenario: I can edit and audit simultaneous updates to the document
    Given I set the date inputs to "19/11/2021"
    And I press "Save"
    And I view the document with reference "FOOBAR"
    And I set the date inputs to "22/11/2021"
    And I choose "No" for "Is the document valid?"
    And I fill in "Describe in full why the document is invalid." with "BANANAS"
    When I press "Save"
    Then there is an audit entry containing "received at date was modified from: 19 November 2021 to: 22 November 2021"
    And there is an audit entry containing "proposed-floorplan.png was marked as invalid"

  Scenario: I can archive and unarchive a document
    Given I manage the documents for the application
    When I press "Archive"
    And I fill in "Why do you want to archive this document?" with "this is not a good photo of me on holiday"
    And I press "Archive"
    Then there is an audit entry containing "Document archived proposed-floorplan.png"
    Then I manage the documents for the application
    And I press "Restore document"
    Then there is an audit entry containing "Document unarchived proposed-floorplan.png"