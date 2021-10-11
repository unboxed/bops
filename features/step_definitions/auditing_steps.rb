# frozen_string_literal: true

Then("there is an audit entry containing {string}") do |content|
  within_table("Activity log") do
    expect(page).to have_content content
  end
end
