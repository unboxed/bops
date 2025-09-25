# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning History" do
  let!(:default_local_authority) { create(:local_authority, :default, :planning_history) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  before do
    sign_in assessor
  end

  context "when planning application's property uprn has planning history" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, uprn: "100081043511", local_authority: default_local_authority)
    end
    let!(:site_history) { create(:site_history, planning_application:) }
    let!(:refused_site_history) { create(:site_history, :refused, planning_application:) }

    before do
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
      click_link "Check site history"
    end

    it "displays relevant planning historical applications", :capybara do
      within("##{site_history.reference}") do
        within(".govuk-summary-card__title-wrapper") do
          expect(page).to have_content(site_history.reference)
          expect(page).to have_selector(".govuk-tag--green", text: "Granted")
          expect(page).to have_content("Decided on #{site_history.date.to_fs(:day_month_year_slashes)}")
        end

        within(".govuk-summary-card__content") do
          expect(page).to have_content("Address: No address given")
          expect(page).to have_content("Description: #{site_history.description}")
        end
      end

      within("##{refused_site_history.reference}") do
        within(".govuk-summary-card__title-wrapper") do
          expect(page).to have_content(refused_site_history.application_number)
          expect(page).to have_selector(".govuk-tag--red", text: "Refused")
          expect(page).to have_content("Decided on #{refused_site_history.date.to_fs(:day_month_year_slashes)}")
        end

        within(".govuk-summary-card__content") do
          expect(page).to have_content("Address: No address given")
          expect(page).to have_content("Description: #{refused_site_history.description}")
        end
      end
    end

    it "allows me to edit a site history", :capybara do
      within("##{site_history.reference}") do
        within(".govuk-summary-card__content") do
          click_link "Edit"
        end
      end
      expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/assessment/site_histories/#{site_history.id}/edit")

      fill_in "Address", with: "12 New Street SE1 1AA"
      click_button "Update site history"
      expect(page).to have_content("Site history was successfully updated")

      within("##{site_history.reference}") do
        within(".govuk-summary-card__content") do
          expect(page).to have_content("Address: 12 New Street SE1 1AA")
        end
      end
    end
  end

  context "when planning application's property uprn has no planning history" do
    let!(:planning_application) do
      create(:planning_application, :in_assessment, uprn: "10008104351", local_authority: default_local_authority)
    end

    before do
      visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
      click_link "Check site history"
    end

    it "displays no planning history for this property" do
      expect(page).to have_content("Check site history")
      expect(page).to have_content("Summary of the relevant historical applications")
      expect(page).to have_content("There is no site history for this property")

      expect(page).to have_selector("span", text: "Add a new site history")
    end
  end
end
