# frozen_string_literal: true

Then("the page contains {string}") do |content|
  expect(page).to have_content(content)
end

Then("the page does not contain {string}") do |content|
  expect(page).not_to have_content(content)
end

Then("the page has a {string} link") do |label|
  expect(page).to have_link(label)
end

Then("the page does not have a {string} link") do |label|
  expect(page).not_to have_link(label)
end

Then("the page has button {string}") do |label|
  expect(page).to have_button(label)
end

Then("the page does not have button {string}") do |label|
  expect(page).not_to have_button(label)
end

Then("the next page is {string}") do |header|
  expect(page.find("h1")).to have_content(header)
end

Then("the page contains an error about {string}") do |msg|
  within(:css, "div.govuk-error-summary") do
    expect(page).to have_content msg
  end
end

Then("the page contains a custom flash about {string}") do |msg|
  within(:css, ".flash") do
    expect(page).to have_content msg
  end
end

Then("I should see the following within {string}") do |caption, table|
  expect(page).to have_table(caption, with_rows: table.rows)
end

Then("I should not see the following within {string}") do |caption, table|
  expect(page).not_to have_table(caption, with_rows: table.rows)
end

Then("I can't press the {string} button") do |string|
  expect(page).to have_button(string, disabled: true)
end

Then("print the page") do
  log page.html
end

Then("debugger") do
  # rubocop:disable Lint/Debugger
  binding.pry
  # rubocop:enable Lint/Debugger
end

When("I press {string}") do |label|
  click_on label
end

When("I fill in {string} with {string}") do |label, value|
  fill_in label, with: value
end

When("I choose {string}") do |option|
  choose option
end

When("I choose {string} for {string}") do |option, legend|
  within_fieldset(legend) do
    choose option
  end
end

When("I check {string}") do |option|
  check option
end

When("I check {string} for {string}") do |option, legend|
  within_fieldset(legend) do
    check option
  end
end

Then("the input for {string} contains {string}") do |label, value|
  expect(page.find_field(label).value).to eq value
end
