# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Enforcement index page", type: :system do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:case_record) { build(:case_record, local_authority:) }
  let!(:case_record_1) { build(:case_record, local_authority:) }
  let!(:enforcement) { create(:enforcement, case_record: case_record, received_at: 1.day.ago) }
  let!(:enforcement_1) { create(:enforcement, case_record: case_record_1, received_at: 3.days.ago) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in user
    visit "/"
  end

  it "allows me to navigate to the enforcement index" do
    expect(page).to have_selector("h1", text: "Planning applications")
    click_link("Enforcement")
    expect(page).to have_current_path("/enforcements")
    expect(page).to have_selector("h1", text: "Enforcement cases")
  end

  it "displays all enforcement cases" do
    visit "/enforcements"
    click_link "All cases"

    within("#all") do
      expect(page).to have_selector("h2", text: "All enforcement cases")

      within(".govuk-table") do
        within(".govuk-table__head") do
          within(all(".govuk-table__row").first) do
            expect(page).to have_content("Case reference")
            expect(page).to have_content("Address")
            expect(page).to have_content("Days received")
            expect(page).to have_content("Status")
            expect(page).to have_content("Priority")
          end
        end

        within(".govuk-table__body") do
          rows = page.all(".govuk-table__row")

          within(rows[0]) do
            cells = page.all(".govuk-table__cell")
            within(cells[0]) do
              expect(page).to have_content(case_record.id)
            end
            within(cells[1]) do
              expect(page).to have_content(enforcement.to_s)
            end
            within(cells[2]) do
              expect(page).to have_content("0 days received")
            end
          end

          within(rows[1]) do
            cells = page.all(".govuk-table__cell")
            within(cells[0]) do
              expect(page).to have_content(case_record_1.id)
            end
            within(cells[1]) do
              expect(page).to have_content(enforcement_1.to_s)
            end
            within(cells[2]) do
              expect(page).to have_content("0 days received")
            end
          end
        end
      end
    end
  end

  it "has a link to the enforcement show page" do
    visit "/enforcements"
    click_link "All cases"
    click_link(enforcement.case_record.id)
    expect(page).to have_current_path("/enforcements/#{enforcement.case_record.id}")
  end

  it "allows me to filter by urgent cases", capybara: true do
    enforcement_1.update(urgent: true)

    visit "/enforcements"
    click_link "All cases"

    within("#filters-section") do
      click_on "Filters"

      check "Urgent"
      click_button "Apply filters"
    end

    within("#filters-content") do
      expect(page).to have_checked_field("Urgent")
    end

    expect(page).to have_content(enforcement_1.to_s)
    expect(page).not_to have_content(enforcement.to_s)
  end
end
