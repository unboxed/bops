# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Dashboard", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:planning_application_1) { create(:planning_application, :pre_application, :in_assessment, local_authority:, user: assessor) }
  let!(:planning_application_2) { create(:planning_application, :pre_application, :in_assessment, local_authority:, user: assessor) }
  let!(:planning_application_started) { create(:planning_application, :pre_application, :awaiting_determination, user: assessor, local_authority:) }
  let!(:reviewer_planning_application_started) { create(:planning_application, :pre_application, :awaiting_determination, user: reviewer, local_authority:) }
  let!(:planning_application_completed) { create(:planning_application, :pre_application, :determined, local_authority:, user: reviewer) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:reviewer) { create(:user, :reviewer, local_authority:) }

  context "as an assessor" do
    before do
      sign_in assessor
      visit "/preapps"
    end

    context "when viewing tabs", :capybara do
      let!(:pre_application_not_started) do
        create(
          :planning_application,
          :pre_application,
          :not_started,
          local_authority:
        )
      end

      let!(:pre_application_in_assessment) do
        create(
          :planning_application,
          :pre_application,
          :in_assessment,
          local_authority:
        )
      end

      it "Planning Application status bar is present" do
        within(:planning_applications_status_tab) do
          expect(page).to have_link "Cases assigned to you"
        end
      end

      it "Planning Application filter options are checked by default" do
        within(selected_govuk_tab) do
          click_on "Filters"

          within(".govuk-accordion__section") do
            expect(page).to have_content("Status")
            expect(page).to have_field("Not started", checked: true)
            expect(page).to have_field("Invalidated", checked: true)
            expect(page).to have_field("In assessment", checked: true)
            expect(page).to have_field("Awaiting determination", checked: true)
            expect(page).to have_field("To be reviewed", checked: true)
          end
        end
      end

      it "Only Planning Applications that are in_assessment are present when filtered" do
        click_link "All"
        expect(page).to have_content("All pre-applications")
        within(selected_govuk_tab) do
          click_on "Filters"
          uncheck "Not started"
          uncheck "Invalidated"
          uncheck "Awaiting determination"
          uncheck "To be reviewed"
          click_button "Apply filters"

          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
          expect(page).not_to have_link(pre_application_not_started.reference)
          expect(page).to have_link(pre_application_in_assessment.reference)
        end
      end

      it "Only Planning Applications that are awaiting_determination are present when filtered" do
        within(selected_govuk_tab) do
          click_on "Filters"
          uncheck "Not started"
          uncheck "Invalidated"
          uncheck "In assessment"
          uncheck "To be reviewed"
          click_button "Apply filters"

          expect(page).to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_1.reference)
          expect(page).not_to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
          expect(page).not_to have_link(pre_application_not_started.reference)
          expect(page).not_to have_link(pre_application_in_assessment.reference)
        end
      end
    end

    context "when I view the closed tab", :capybara do
      let!(:withdrawn_planning_application) do
        create(
          :planning_application,
          :pre_application,
          :withdrawn,
          withdrawn_at: DateTime.new(2022, 8, 2),
          address_1: "2 Long Lane",
          town: "London",
          postcode: "AB3 4EF",
          description: "Add a window",
          local_authority:,
          user: assessor
        )
      end

      let!(:closed_planning_application) do
        create(
          :planning_application,
          :pre_application,
          :closed,
          closed_at: DateTime.new(2022, 8, 4),
          address_1: "4 Long Lane",
          town: "London",
          postcode: "AB3 4EF",
          description: "Add an attic",
          local_authority:,
          user: assessor
        )
      end

      before do
        planning_application_1.update(status: "withdrawn", withdrawn_at: DateTime.new(2022, 8, 2))
        visit "/preapps"
        click_on "Closed"
      end

      it "shows closed application" do
        within("#closed") do
          row = row_with_content(closed_planning_application.reference)
          expect(row).to have_content("Closed")
          expect(row).to have_content("4 Aug")
          expect(row).to have_content("4 Long Lane, London, AB3 4EF")
          expect(row).to have_content("Add an attic")
        end
      end

      it "shows withdrawn applications" do
        within("#closed") do
          row = row_with_content(planning_application_1.reference)
          expect(row).to have_content("Withdrawn")
          expect(row).to have_content("2 August 2022")
          expect(row).to have_content(planning_application_1.description)

          row = row_with_content(withdrawn_planning_application.reference)
          expect(row).to have_content("Withdrawn")
          expect(row).to have_content("2 August 2022")
          expect(row).to have_content(withdrawn_planning_application.description)
        end
      end

      context "when a planning application is pending" do
        let!(:planning_application) do
          create(
            :planning_application,
            :pre_application,
            :pending,
            local_authority:,
            address_1: "Pending lane"
          )
        end

        it "does not display the application" do
          click_link "All"
          expect(page).not_to have_content("Pending lane")
        end
      end
    end

    context "when searching", :capybara do
      before do
        sign_in assessor
        visit "/preapps"
      end

      it "displays section navigation after search" do
        expect(page).to have_css(".govuk-service-navigation")

        within(selected_govuk_tab) do
          fill_in("Find an application", with: planning_application_1.reference)
          click_button("Search")
        end

        expect(page).to have_css(".govuk-service-navigation")
        expect(page).to have_link("Pre-application")
        expect(page).to have_link("Planning")
        expect(page).to have_link("Enforcement")
      end
    end
  end
end
