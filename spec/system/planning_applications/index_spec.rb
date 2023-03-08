# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application index page" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  let!(:planning_application_1) { create(:planning_application, :in_assessment, user: assessor, local_authority: default_local_authority) }
  let!(:planning_application_2) { create(:planning_application, :in_assessment, user: assessor, local_authority: default_local_authority) }
  let!(:planning_application_started) do
    create(:planning_application, :awaiting_determination, user: assessor, local_authority: default_local_authority)
  end
  let!(:reviewer_planning_application_started) do
    create(:planning_application, :awaiting_determination, user: reviewer, local_authority: default_local_authority)
  end
  let!(:planning_application_completed) do
    create(:planning_application, :determined, local_authority: default_local_authority)
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit root_path
    end

    context "when a planning application is awaiting correction" do
      before do
        create(
          :planning_application,
          :awaiting_correction,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit root_path

        expect(page).to have_content(
          "Your manager has requested corrections on 1 application."
        )
      end
    end

    context "when multiple planning applications are awaiting correction" do
      before do
        create_list(
          :planning_application,
          2,
          :awaiting_correction,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit root_path

        expect(page).to have_content(
          "Your manager has requested corrections on 2 applications."
        )
      end
    end

    context "when viewing tabs" do
      it "Planning Application status bar is present" do
        within(:planning_applications_status_tab) do
          expect(page).to have_link "Your live applications"
        end
      end

      it "Only Planning Applications that are in_assessment are present when filtered" do
        click_on "Filter by status (5 of 5 selected)"
        uncheck "Not started"
        uncheck "Invalidated"
        uncheck "Awaiting determination"
        uncheck "To be reviewed"
        click_button "Apply filters"

        within(selected_govuk_tab) do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
        end
      end

      it "Only Planning Applications that are awaiting_determination are present when filtered" do
        click_on "Filter by status (5 of 5 selected)"
        uncheck "Not started"
        uncheck "Invalidated"
        uncheck "In assessment"
        uncheck "To be reviewed"
        click_button "Apply filters"

        within(selected_govuk_tab) do
          expect(page).to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_1.reference)
          expect(page).not_to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
        end
      end

      context "when I view the closed tab" do
        let!(:determined_planning_application) do
          create(
            :planning_application,
            :determined,
            decision: :granted,
            determined_at: DateTime.new(2022, 8, 1),
            address_1: "1 Long Lane",
            town: "London",
            postcode: "AB3 4EF",
            description: "Add a fence",
            local_authority: default_local_authority,
            user: assessor
          )
        end

        let!(:withdrawn_planning_application) do
          create(
            :planning_application,
            :withdrawn,
            withdrawn_at: DateTime.new(2022, 8, 2),
            address_1: "2 Long Lane",
            town: "London",
            postcode: "AB3 4EF",
            description: "Add a window",
            local_authority: default_local_authority,
            user: assessor
          )
        end

        let!(:returned_planning_application) do
          create(
            :planning_application,
            :returned,
            returned_at: DateTime.new(2022, 8, 3),
            address_1: "3 Long Lane",
            town: "London",
            postcode: "AB3 4EF",
            description: "Add a chimney",
            local_authority: default_local_authority,
            user: assessor
          )
        end

        let!(:closed_planning_application) do
          create(
            :planning_application,
            :closed,
            closed_at: DateTime.new(2022, 8, 4),
            address_1: "4 Long Lane",
            town: "London",
            postcode: "AB3 4EF",
            description: "Add an attic",
            local_authority: default_local_authority,
            user: assessor
          )
        end

        let!(:other_closed_planning_application) do
          create(
            :planning_application,
            :closed,
            closed_at: DateTime.new(2022, 8, 4),
            address_1: "4 Long Lane",
            town: "London",
            postcode: "AB3 4EF",
            description: "Add an attic",
            local_authority: default_local_authority,
            user: reviewer
          )
        end

        before do
          visit(root_path)
          click_on "Closed"
        end

        it "shows determined application" do
          row = row_with_content(determined_planning_application.reference)
          expect(row).to have_content("Granted")
          expect(row).to have_content("1 Aug")
          expect(row).to have_content("1 Long Lane, London, AB3 4EF")
          expect(row).to have_content("Add a fence")
        end

        it "shows withdrawn application" do
          within(selected_govuk_tab) do
            row = row_with_content(withdrawn_planning_application.reference)
            expect(row).to have_content("Withdrawn")
            expect(row).to have_content("2 Aug")
            expect(row).to have_content("2 Long Lane, London, AB3 4EF")
            expect(row).to have_content("Add a window")
          end
        end

        it "shows returned application" do
          within(selected_govuk_tab) do
            row = row_with_content(returned_planning_application.reference)
            expect(row).to have_content("Returned")
            expect(row).to have_content("3 Aug")
            expect(row).to have_content("3 Long Lane, London, AB3 4EF")
            expect(row).to have_content("Add a chimney")
          end
        end

        it "shows closed application" do
          within(selected_govuk_tab) do
            row = row_with_content(closed_planning_application.reference)
            expect(row).to have_content("Closed")
            expect(row).to have_content("4 Aug")
            expect(row).to have_content("4 Long Lane, London, AB3 4EF")
            expect(row).to have_content("Add an attic")
          end
        end

        it "only shows your own applications" do
          within(selected_govuk_tab) do
            expect(page).not_to have_content(other_closed_planning_application.reference)
          end
        end
      end

      context "when I view the 'All applications' tab" do
        let!(:planning_application) do
          create(
            :planning_application,
            :not_started,
            address_1: "1 Long Lane",
            town: "London",
            postcode: "AB3 4EF",
            description: "Add a fence",
            created_at: DateTime.new(2022, 1, 1),
            local_authority: default_local_authority
          )
        end

        it "shows relevant application details" do
          visit(planning_applications_path)
          click_link("All applications")

          within(selected_govuk_tab) do
            expect(page).to have_content("All applications")
            row = row_with_content(planning_application.reference)
            expect(row).to have_content("Not started")
            expect(row).to have_content("1 Mar")
            expect(row).to have_content("1 Long Lane, London, AB3 4EF")
            expect(row).to have_content("Add a fence")
          end
        end
      end

      context "when I view the 'All your applications' tab" do
        let!(:planning_application) do
          create(
            :planning_application,
            :not_started,
            address_1: "1 Long Lane",
            town: "London",
            postcode: "AB3 4EF",
            description: "Add a fence",
            created_at: DateTime.new(2022, 1, 1),
            local_authority: default_local_authority
          )
        end

        it "shows relevant application details" do
          visit(planning_applications_path(q: "exclude_others"))

          within(selected_govuk_tab) do
            expect(page).to have_content("Your live applications")
            row = row_with_content(planning_application.reference)
            expect(row).to have_content("Not started")
            expect(row).to have_content("1 Mar")
            expect(row).to have_content("1 Long Lane, London, AB3 4EF")
          end
        end
      end

      it "Breadcrumbs are not displayed" do
        expect(find(".govuk-breadcrumbs__list").text).to be_empty
      end

      it "User can log out from index page" do
        click_link "Log out"

        expect(page).to have_current_path(/sign_in/)
        expect(page).to have_content("You need to sign in or sign up before continuing.")
      end
    end

    context "with restricted views" do
      let!(:second_assessor) { create(:user, :assessor, local_authority: default_local_authority) }
      let!(:other_assessor_planning_application) do
        create(:planning_application, user_id: second_assessor.id, local_authority: default_local_authority)
      end
      let(:recommendation) { create(:recommendation, planning_application: other_assessor_planning_application) }

      it "On login, assessor gets redirected to a view with all their Planning Applications" do
        within(selected_govuk_tab) do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).to have_link(planning_application_started.reference)
          expect(page).not_to have_link(other_assessor_planning_application.reference)
        end
      end

      it "An assessor can click a button to view all applications" do
        click_on "View all applications"

        within("#under_assessment") do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).to have_link(other_assessor_planning_application.reference)
        end
      end

      it "An aassessor can click back to view only its own applications" do
        click_on "View all applications"

        click_on "View my applications"

        within(selected_govuk_tab) do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).not_to have_link(other_assessor_planning_application.reference)
        end
      end

      it "Applications in a determined state belonging to other assessors are also not visible on login" do
        other_assessor_planning_application.recommendations << recommendation

        other_assessor_planning_application.decision = "granted"
        other_assessor_planning_application.assess!
        other_assessor_planning_application.submit!
        other_assessor_planning_application.determine!

        click_link "Closed"

        within("#closed") do
          expect(page).not_to have_link(other_assessor_planning_application.reference)
        end

        click_on "View all applications"
        click_link "Closed"

        within("#closed") do
          expect(page).to have_link(other_assessor_planning_application.reference)
        end
      end
    end
  end

  context "as a reviewer" do
    before do
      sign_in reviewer
      visit root_path
    end

    context "when planning application is awaiting correction" do
      before do
        create(
          :planning_application,
          :awaiting_correction,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit root_path

        expect(page).to have_content(
          "You have 1 application returned to you with corrections."
        )
      end
    end

    context "when multiple planning applications are awaiting correction" do
      before do
        create_list(
          :planning_application,
          2,
          :awaiting_correction,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit root_path

        expect(page).to have_content(
          "You have 2 applications returned to you with corrections."
        )
      end
    end

    it "Planning Application status bar is present and does not show In Assessment by default" do
      within(:planning_applications_status_tab) do
        expect(page).to have_link "Your live applications"
        expect(page).to have_link "Closed"
      end
    end

    it "Reviewer can see applications in assessment status by toggling link" do
      click_link "View all applications"

      within(:planning_applications_status_tab) do
        expect(page).to have_link "Awaiting determination"
        expect(page).to have_link "Closed"
        expect(page).to have_text "In assessment"
      end

      click_link "View assessed applications"

      within(:planning_applications_status_tab) do
        expect(page).to have_link "Your live applications"
        expect(page).to have_link "Closed"
      end
    end

    it "Only Planning Applications that are awaiting_determination are present in this tab" do
      click_on "Filter by status (2 of 2 selected)"
      uncheck "To be reviewed"
      click_button "Apply filters"

      within(selected_govuk_tab) do
        expect(page).to have_link(reviewer_planning_application_started.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_completed.reference)
      end
    end

    it "Only Planning Applications that are determined are present in this tab" do
      click_link "Closed"

      within("#closed") do
        expect(page).to have_text("Closed")
        expect(page).to have_link(planning_application_completed.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_started.reference)
      end
    end

    it "Breadcrumbs are not displayed" do
      expect(find(".govuk-breadcrumbs__list").text).to be_empty
    end
  end
end
