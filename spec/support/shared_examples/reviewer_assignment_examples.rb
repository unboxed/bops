# frozen_string_literal: true

RSpec.shared_examples 'reviewer assignment' do
  scenario "reviewer is not assigned to planning application" do
    click_link "19/AP/1880"

    click_link "Review permitted development policy requirements"

    click_link "Home"

    table_rows = all(".govuk-table__row").map(&:text)

    table_rows.each do |row|
      expect(row).not_to include("Harley Dicki") if row.include? "19/AP/1880"
    end
  end
end
