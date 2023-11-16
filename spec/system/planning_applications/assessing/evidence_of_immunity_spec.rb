# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Evidence of immunity" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :in_assessment, :with_immunity, local_authority: default_local_authority)
  end

  context "when signed in as an assessor" do
    before do
      create(:evidence_group, :with_document, tag: "utility_bill", immunity_detail: planning_application.immunity_detail)
      create(:evidence_group, :with_document, tag: "building_control_certificate", end_date: nil, immunity_detail: planning_application.immunity_detail)

      sign_in assessor
      visit planning_application_path(planning_application)
    end

    context "when planning application is in assessment" do
      it "I can view the information on the evidence of immunity page" do
        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "Not started"
        )

        click_link("Evidence of immunity")

        within(".govuk-breadcrumbs__list") do
          expect(page).to have_content("Evidence of immunity")
        end

        expect(page).to have_current_path(
          "/planning_applications/#{planning_application.id}/assessment/immunity_details/new"
        )

        within(".govuk-heading-l") do
          expect(page).to have_content("Evidence of immunity")
        end
        expect(page).to have_content("Application number: #{planning_application.reference}")
        expect(page).to have_content(planning_application.full_address)

        expect(page).to have_content("Were the works carried out more than 4 years ago? Yes")
        expect(page).to have_content("Have the works been completed? Yes")
        expect(page).to have_content("When were the works completed? 01/02/2015")
        expect(page).to have_content("Has anyone ever attempted to conceal the changes? No")
        expect(page).to have_content("Has enforcement action been taken about these changes? No")

        click_button "Utility bills (1)"
        utility_bill_group = planning_application.immunity_detail.evidence_groups.where(tag: "utility_bill").first

        within(open_accordion_section) do
          within_fieldset("Starts from") do
            expect(page).to have_field("Day", with: utility_bill_group.start_date.strftime("%-d"))
            expect(page).to have_field("Month", with: utility_bill_group.start_date.strftime("%-m"))
            expect(page).to have_field("Year", with: utility_bill_group.start_date.strftime("%Y"))
          end

          within_fieldset("Runs until") do
            expect(page).to have_field("Day", with: utility_bill_group.end_date.strftime("%-d"))
            expect(page).to have_field("Month", with: utility_bill_group.end_date.strftime("%-m"))
            expect(page).to have_field("Year", with: utility_bill_group.end_date.strftime("%Y"))
          end

          expect(page).to have_content("This is my proof")

          expect(page).to have_content(utility_bill_group.documents.first.numbers)
        end
      end

      it "I can save and come back later when adding or editing the immunity evidence" do
        click_link "Check and assess"
        click_link "Evidence of immunity"

        click_button "Utility bills (1)"

        within(open_accordion_section) do
          within_fieldset("Runs until") do
            fill_in "Day", with: "03"
            fill_in "Month", with: "12"
            fill_in "Year", with: "2021"
          end

          fill_in "Add comment", with: "This is my comment"
        end

        click_button "Save and come back later"

        expect(page).to have_content("Evidence of immunity successfully updated")

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "In progress"
        )

        click_link("Evidence of immunity")

        click_button "Utility bills (1)"

        within(open_accordion_section) do
          within_fieldset("Runs until") do
            expect(page).to have_field("Day", with: "3")
            expect(page).to have_field("Month", with: "12")
            expect(page).to have_field("Year", with: "2021")
          end

          find("span", text: "Previous comments").click

          expect(page).to have_content("This is my comment")
        end

        click_link("Application")

        expect(list_item("Check and assess")).to have_content("In progress")
      end

      it "I can save and mark as complete the evidence of immunity" do
        click_link "Check and assess"
        click_link "Evidence of immunity"

        click_button "Utility bills (1)"

        within(open_accordion_section) do
          check "Missing evidence (gap in time)"
          fill_in "List all the gap(s) in time", with: "May 2019"
          fill_in "Add comment", with: "Not good enough"
        end

        click_button "Utility bills (1)"

        click_button "Building control certificates (1)"

        within(open_accordion_section) do
          fill_in "Add comment", with: "This proves it"
        end

        click_button "Save and mark as complete"

        expect(page).to have_content("Evidence of immunity successfully updated")

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "Completed"
        )

        click_link "Evidence of immunity"

        expect(page).to have_content("Edit evidence of immunity")
        expect(page).not_to have_content("Save and mark as complete")

        click_button "Utility bills (1)"

        within(:xpath, "//*[@class='govuk-accordion__section govuk-accordion__section--expanded']") do
          expect(page).to have_field("List all the gap(s) in time", with: "May 2019", disabled: true)
          expect(page).to have_css(".govuk-warning-text__icon")

          find("span", text: "Previous comments").click
          expect(page).to have_content("Not good enough")
        end

        click_button "Utility bills (1)"

        click_button "Building control certificates (1)"

        within(:xpath, "//*[@class='govuk-accordion__section govuk-accordion__section--expanded']") do
          find("span", text: "Previous comments").click
          expect(page).to have_content("This proves it")
        end
      end
    end
  end

  context "when planning application has not been validated yet" do
    let!(:planning_application) do
      create(:planning_application, :not_started, local_authority: default_local_authority)
    end

    it "does not allow me to visit the page" do
      sign_in assessor
      visit planning_application_path(planning_application)

      expect(page).not_to have_link("Evidence of immunity")

      visit new_planning_application_assessment_immunity_detail_path(planning_application)

      expect(page).to have_content("forbidden")
    end
  end
end
