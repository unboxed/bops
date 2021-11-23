Feature: Editing documents for an application
  Background:
    Given I am logged in as an assessor
    And a new planning application
    And the planning application has a document with reference "FOOBAR"
    And I view the planning application

  Scenario: I can replace the document
    Given I view the document with reference "FOOBAR"
    And I attach a replacement file with path "spec/fixtures/images/proposed-roofplan.pdf"
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
