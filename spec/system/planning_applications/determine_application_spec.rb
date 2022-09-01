# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let(:default_local_authority) do
    create(
      :local_authority,
      :default,
      signatory_name: "Jane Smith",
      signatory_job_title: "Director"
    )
  end

  let!(:planning_application) do
    create(:planning_application, :awaiting_determination,
           local_authority: default_local_authority,
           decision: "granted")
  end

  context "when the planning application is awaiting determination" do
    context "when I'm signed in as a reviewer" do
      let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

      before do
        travel_to Time.zone.local(2024, 2, 1)
        sign_in(reviewer)
        visit planning_application_path(planning_application)
      end

      it "I can determine the application" do
        click_link("Publish determination")

        expect(page).to have_content(
          "By determining the application, the applicant will receive this decision notice."
        )

        expect(page).not_to have_content(
          "Awaiting approval to a description change"
        )

        within("#determination-date") do
          expect(page).to have_content("Enter determination date")

          # Date form field is prefilled with today's date
          expect(find("#planning_application_determination_date_3i").value).to eq("1")
          expect(find("#planning_application_determination_date_2i").value).to eq("2")
          expect(find("#planning_application_determination_date_1i").value).to eq("2024")

          # Enter date in the future
          fill_in "Day", with: "03"
          fill_in "Month", with: "12"
          fill_in "Year", with: "2024"
        end

        click_button("Determine application")

        within(find_all(".govuk-error-summary").last) do
          expect(page).to have_content("Determination date must be today or in the past")
        end

        within(".govuk-error-message") do
          expect(page).to have_content("Determination date must be today or in the past")
        end

        within("#determination-date") do
          # Enter date today
          fill_in "Day", with: "2"
          fill_in "Month", with: "1"
          fill_in "Year", with: "2024"
        end

        click_button("Determine application")

        expect(page).to have_content("Decision Notice sent to applicant")

        expect(page).to have_content("Granted at: 2 January 2024")
        expect(page).to have_link(
          "View decision notice",
          href: decision_notice_planning_application_path(planning_application)
        )

        click_link("View decision notice")

        expect(page).to have_content(
          "Certificate of Lawful Use or Development Granted"
        )

        expect(page).to have_content("Jane Smith, Director")

        visit planning_application_path(planning_application)

        # Check latest audit
        click_button "Audit log"
        within("#latest-audit") do
          expect(page).to have_content("Decision Published")
          expect(page).to have_text("Application granted on 2 January 2024 (manually inputted date)")
          expect(page).to have_text(reviewer.name)
          expect(page).to have_text(Audit.last.created_at.strftime("%H:%M"))

          click_link "View all audits"
        end

        # Check audit logs
        within("#audit_#{Audit.last.id}") do
          expect(page).to have_content("Decision Published")
          expect(page).to have_text("Application granted on 2 January 2024 (manually inputted date)")
          expect(page).to have_text(reviewer.name)
          expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end

      context "when open description_change_validation_request" do
        before do
          create(
            :description_change_validation_request,
            :open,
            planning_application: planning_application,
            created_at: DateTime.new(2024, 1, 1)
          )
        end

        it "shows warning but allows user to determine application" do
          click_link("Publish determination")

          expect(page).to have_content(
            "Awaiting approval to a description change (sent on 01/01/2024)"
          )

          fill_in("Day", with: "2")
          fill_in("Month", with: "1")
          fill_in("Year", with: "2024")
          click_button("Determine application")

          expect(page).to have_content("Decision Notice sent to applicant")
        end
      end
    end

    context "when I'm signed in as an assessor" do
      let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

      before do
        sign_in(assessor)
        visit planning_application_path(planning_application)
      end

      it "I cannot determine the application" do
        expect(page).not_to have_link("Publish determination")
      end
    end
  end
end
