# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning History" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor

    ENV["PLANNING_HISTORY_ENABLED"] = "true"
  end

  context "when planning application's property uprn has planning history" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, uprn: "100081043511", local_authority: default_local_authority)
    end

    before do
      visit planning_application_assessment_tasks_path(planning_application)
      click_link "History search (in testing)"
    end

    it "displays a table with relevants planning historical applications" do
      within(".govuk-table.planning-history-table") do
        within(".govuk-table__head") do
          within(all(".govuk-table__row").first) do
            expect(page).to have_content("Date")
            expect(page).to have_content("Application number")
            expect(page).to have_content("Description")
            expect(page).to have_content("Recommendation")
            expect(page).to have_content("View on public access")
          end
        end

        within(".govuk-table__body") do
          rows = page.all(".govuk-table__row")

          within(rows[0]) do
            cells = page.all(".govuk-table__cell")

            within(cells[0]) do
              expect(page).to have_content("16 September 2022")
            end
            within(cells[1]) do
              expect(page).to have_content("22/06601/FUL")
            end
            within(cells[2]) do
              expect(page).to have_content("Householder application for construction of detached two storey double garage with external staircase")
            end
            within(cells[3]) do
              expect(page).to have_content("Application Refused")
            end
            within(cells[4]) do
              expect(page).to have_link("View")
            end
          end

          within(rows[1]) do
            cells = page.all(".govuk-table__cell")

            within(cells[0]) do
              expect(page).to have_content("16 September 2022")
            end
            within(cells[1]) do
              expect(page).to have_content("PL/22/2428/SA")
            end
            within(cells[2]) do
              expect(page).to have_content("Certificate of lawfulness for proposed loft conversion including hip to gable roof extensions to both sides, rear dormer window, 3 front and 1 rear rooflights and 4 side windows")
            end
            within(cells[3]) do
              expect(page).to have_content("Cert of law for proposed dev/use refused")
            end
            within(cells[4]) do
              expect(page).to have_link("View")
            end
          end

          within(rows[2]) do
            cells = page.all(".govuk-table__cell")

            within(cells[0]) do
              expect(page).to have_content("16 September 2022")
            end
            within(cells[1]) do
              expect(page).to have_content("PL/22/2883/KA")
            end
            within(cells[2]) do
              expect(page).to have_content("T1 English oak - crown reduction by approx 4.5m, T2 sycamore - crown reduction by approx 2.5m (Chesham Bois Conservation Area)")
            end
            within(cells[3]) do
              expect(page).to have_content("TPO shall not be made")
            end
            within(cells[4]) do
              expect(page).to have_link("View")
            end
          end
        end
      end
    end
  end

  context "when planning application's property uprn has not planning history" do
    let!(:planning_application) do
      create(:planning_application, :invalidated, uprn: "10008104351", local_authority: default_local_authority)
    end

    before do
      visit planning_application_assessment_tasks_path(planning_application)
      click_link "History search (in testing)"
    end

    it "displays no planning history for this property" do
      expect(page).to have_content("Review the planning history")
      expect(page).to have_content("Planning application for UPRN 10008104351")
      expect(page).to have_content("There is no planning history for this property")
    end
  end
end
