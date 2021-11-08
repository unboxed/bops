# frozen_string_literal: true

When("I view the planning application notes") do
  visit planning_application_notes_path(@planning_application)
end

When("I see the note form actions") do
  within(".govuk-button-group") do
    steps %(
      Then the page has button "Add new note"
      And the page has a "Back" link with href "#{planning_application_path(@planning_application)}"
    )
  end
end

Then("I see that there are no notes") do
  steps %(
    And the page contains "There are no notes yet."
    And the page does not contain "Current note"
    And the page does not contain "Previous notes"
  )
end

Then("I see that there is one note") do
  steps %(
    And the page does not contain "There are no notes yet."
    And the page contains "Current note"
    And the page does not contain "Previous notes"
  )
end

Then("I see that there is a note with entry {string} at {string}") do |entry, day_month_year_time|
  note = @planning_application.notes.find_by(entry: entry)

  within("#notes") do
    within("#note_#{note.id}") do
      steps %(
        And the page contains "#{note.user.name}"
        And the page contains "#{day_month_year_time}"
        And the page contains "#{entry}"
      )
    end
  end
end

Then("I see that there are multiple notes") do
  within("#notes") do
    steps %(
      And the page contains "Current note"
      And the page contains "Previous notes"
    )
  end
end

Given("I add a note with {string}") do |entry|
  steps %(
    Given I fill in "Add a note to this application. This will replace the current note." with "#{entry}"
    And I see the note form actions
    And I press "Add new note"
    Then the page contains "Note was successfully created."
  )
end

When("I see the current note with entry {string} at {string}") do |entry, day_month_year|
  steps %(
    Then the page contains "#{entry}"
    And the page contains "#{day_month_year}"
  )
end
