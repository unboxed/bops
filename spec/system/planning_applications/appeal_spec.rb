# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Appeal" do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :prior_approval) }
  let(:planning_application) do
    travel_to(DateTime.new(2024, 10, 11)) do
      create(:planning_application, application_type:, local_authority:)
    end
  end

  before do
    sign_in assessor

    travel_to(DateTime.new(2024, 11, 11))
    visit "/planning_applications/#{planning_application.reference}"
  end

  context "when there is an appeal" do
    it "I am able to mark the application for appeal and proceed to process it for a decision." do
      click_link "Mark for appeal"
      expect(page).to have_selector("h1", text: "Mark application for appeal")

      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "Enter the date when the appeal was lodged")
      expect(page).to have_selector("[role=alert] li", text: "Enter a reason for the appeal")

      fill_in "Day", with: "11"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was lodged must be a valid date")

      fill_in "Day", with: "12"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was lodged must be on or before today")

      fill_in "Day", with: "9"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"

      fill_in "Enter appeal reason", with: "The applicant disagrees with the application decision."
      attach_file("Upload documents", "spec/fixtures/files/appeal.png")

      click_button("Save")
      expect(page).to have_content("Application was successfully marked for appeal")

      within("#planning-application-details") do
        expect(page).to have_selector("span.govuk-tag.govuk-tag--purple", text: "Appeal lodged")
      end

      expect(Audit.find_by_activity_type("appeal_updated")).to have_attributes(
        planning_application_id: planning_application.id,
        audit_comment: "Appeal status was updated to lodged on 9 November 2024",
        user: assessor
      )

      click_link "Update appeal"
      within("#appeal-documents") do
        expect(page).to have_link("View in new window")
        expect(page).to have_selector("strong.govuk-tag.govuk-tag--turquoise", text: "Appeal")
        expect(page).to have_selector("p", text: "File name: appeal.png")
        expect(page).to have_selector("p", text: "Date received: 11 November 2024")
      end

      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Enter the date when the appeal was valid")

      fill_in "Day", with: "11"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was valid must be a valid date")

      fill_in "Day", with: "12"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was valid must be on or before today")

      fill_in "Day", with: "8"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was valid must be on or after the lodged at date")

      fill_in "Day", with: "10"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")

      expect(page).to have_content("Appeal was successfully updated as valid")

      within("#planning-application-details") do
        expect(page).to have_selector("span.govuk-tag.govuk-tag--purple", text: "Appeal valid")
      end
      expect(page).to have_content("The applicant disagrees with the application decision.")

      expect(Audit.last).to have_attributes(
        activity_type: "appeal_updated",
        audit_comment: "Appeal status was updated to validated on 10 November 2024",
        user: assessor
      )

      click_link "Update appeal"
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Enter the date when the appeal was started")

      fill_in "Day", with: "11"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was started must be a valid date")

      fill_in "Day", with: "12"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was started must be on or before today")

      fill_in "Day", with: "8"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was started must be on or after the valid at date")

      fill_in "Day", with: "10"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")

      expect(page).to have_content("Appeal was successfully updated as started")

      within("#planning-application-details") do
        expect(page).to have_selector("span.govuk-tag.govuk-tag--purple", text: "Appeal started")
      end

      expect(Audit.last).to have_attributes(
        activity_type: "appeal_updated",
        audit_comment: "Appeal status was updated to started on 10 November 2024",
        user: assessor
      )

      click_link "Update appeal"
      click_button "Save"
      expect(page).to have_selector("[role=alert] li", text: "Choose a decision for the appeal")
      expect(page).to have_selector("[role=alert] li", text: "Enter the date when the appeal was determined")

      fill_in "Day", with: "11"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was determined must be a valid date")

      fill_in "Day", with: "12"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was determined must be on or before today")

      fill_in "Day", with: "8"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"
      click_button("Save")
      expect(page).to have_selector("[role=alert] li", text: "The date the appeal was determined must be on or after the started at date")

      choose "Split decision"
      fill_in "Day", with: "11"
      fill_in "Month", with: "11"
      fill_in "Year", with: "2024"

      attach_file("Upload documents", "spec/fixtures/files/appeal-decision.jpg")
      click_button("Save")

      expect(page).to have_content("Appeal decision was successfully updated")

      within("#planning-application-details") do
        expect(page).to have_selector("span.govuk-tag.govuk-tag--purple", text: "Appeal split decision")
      end

      expect(Audit.where(activity_type: "appeal_updated").last).to have_attributes(
        activity_type: "appeal_updated",
        audit_comment: "Appeal status was updated to determined on 11 November 2024",
        user: assessor
      )
      expect(Audit.find_by_activity_type("appeal_decision")).to have_attributes(
        planning_application_id: planning_application.id,
        audit_comment: "Appeal decision was updated to split decision on 11 November 2024",
        user: assessor
      )

      within("#appeal-documents") do
        within("#document_#{Appeal.last.documents.last.id}") do
          expect(page).to have_link("View in new window")
          expect(page).to have_selector("strong.govuk-tag.govuk-tag--turquoise", text: "Appeal Decision")
          expect(page).to have_selector("p", text: "File name: appeal-decision.jpg")
          expect(page).to have_selector("p", text: "Date received: 11 November 2024")
        end
      end

      within("table#appeals") do
        expect(page).to have_selector("caption.govuk-table__caption--m", text: "Appeal history")

        within "thead > tr:first-child" do
          expect(page).to have_selector("th:nth-child(1)", text: "Date")
          expect(page).to have_selector("th:nth-child(2)", text: "Activity")
        end

        within "tbody" do
          within "tr:nth-child(1)" do
            expect(page).to have_selector("td:nth-child(1)", text: "9 November 2024")
            expect(page).to have_selector("td:nth-child(2)", text: "Appeal lodged")
          end

          within "tr:nth-child(2)" do
            expect(page).to have_selector("td:nth-child(1)", text: "10 November 2024")
            expect(page).to have_selector("td:nth-child(2)", text: "Appeal validated")
          end

          within "tr:nth-child(3)" do
            expect(page).to have_selector("td:nth-child(1)", text: "10 November 2024")
            expect(page).to have_selector("td:nth-child(2)", text: "Appeal started")
          end

          within "tr:nth-child(4)" do
            expect(page).to have_selector("td:nth-child(1)", text: "11 November 2024")
            expect(page).to have_selector("td:nth-child(2)", text: "Appeal split decision")
          end
        end
      end
    end

    context "when application type does not support appeals" do
      let(:application_type) do
        create(:application_type, features: {appeals: false})
      end

      it "I cannot mark an application for appeal" do
        expect(page).not_to have_link("Mark for appeal")

        visit "/planning_applications/#{planning_application.reference}/appeal"
        expect(page).to have_selector(".govuk-notification-banner__content", text: "Appeals are not permitted for this application type")
      end
    end
  end
end
