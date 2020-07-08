# frozen_string_literal: true

RSpec.shared_examples 'reviewer assignment' do
  scenario "reviewer is not assigned to planning application" do
    click_link planning_application.reference

    click_link "Review the recommendation"

    click_link "Home"

    table_rows = all(".govuk-table__row").map(&:text)

    table_rows.each do |row|
      expect(row).not_to include("Harley Dicki") if row.include? "00000001"
    end
  end
end
