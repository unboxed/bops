# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application index page", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:application_type_ldc_proposed) { create(:application_type, :ldc_proposed, local_authority: default_local_authority) }
  let!(:application_type_prior_approval) { create(:application_type, :prior_approval, local_authority: default_local_authority) }
  let!(:planning_application_1) {
    create(:planning_application, :ldc_proposed, :in_assessment, local_authority: default_local_authority, application_type: application_type_ldc_proposed)
  }
  let!(:planning_application_2) {
    create(:planning_application, :ldc_proposed, :in_assessment, local_authority: default_local_authority, application_type: application_type_ldc_proposed)
  }
  let!(:planning_application_started) do
    create(:planning_application, :ldc_proposed, :awaiting_determination, user: assessor, local_authority: default_local_authority, application_type: application_type_ldc_proposed)
  end
  let!(:reviewer_planning_application_started) do
    create(:planning_application, :awaiting_determination, user: reviewer, local_authority: default_local_authority)
  end
  let!(:planning_application_completed) do
    create(:planning_application, :determined, local_authority: default_local_authority)
  end
  let(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  context "as an assessor" do
    before do
      sign_in assessor
      visit "/"
    end

    context "when a planning application is to be reviewed" do
      before do
        create(
          :planning_application,
          :to_be_reviewed,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit "/"

        expect(page).to have_content(
          "Reviewer requests 1 application "
        )
      end
    end

    context "when multiple planning applications are to be reviewed" do
      before do
        create_list(
          :planning_application,
          2,
          :to_be_reviewed,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit "/"

        expect(page).to have_content(
          "Reviewer requests 2 applications "
        )
      end
    end

    context "when a prior approval is not started" do
      before do
        create(
          :planning_application,
          :not_started,
          :from_planx_prior_approval,
          application_type: application_type_prior_approval,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit "/"
        expect(page).to have_content("Not started 1 prior approval ")
      end
    end

    context "when multiple prior approvals are not started" do
      before do
        create_list(
          :planning_application,
          2,
          :not_started,
          :from_planx_prior_approval,
          application_type: application_type_prior_approval,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit "/"
        expect(page).to have_content("Not started 2 prior approvals ")
      end

      context "when one gets marked as started" do
        before do
          app = PlanningApplication.prior_approvals.not_started.last
          app.update!(validated_at: Time.zone.today)
          app.start
          app.save!
        end

        it "alters the alert message" do
          visit "/"
          expect(page).to have_content("Not started 1 prior approval ")
        end
      end
    end

    context "when viewing tabs", :capybara do
      let!(:prior_approval_not_started) do
        create(
          :planning_application,
          :not_started,
          :prior_approval,
          local_authority: default_local_authority,
          application_type: application_type_prior_approval
        )
      end

      let!(:prior_approval_in_assessment) do
        create(
          :planning_application,
          :in_assessment,
          :prior_approval,
          local_authority: default_local_authority,
          application_type: application_type_prior_approval
        )
      end

      it "Planning Application status bar is present" do
        within(:planning_applications_status_tab) do
          expect(page).to have_link "Your live applications"
        end
      end

      it "Planning Application filter options are checked by default" do
        click_on "Filters"

        within(".govuk-accordion__section") do
          expect(page).to have_content("Application type")
          expect(page).to have_field("Lawfulness certificate", checked: true)
          expect(page).to have_field("Prior approval", checked: true)

          expect(page).to have_content("Status")
          expect(page).to have_field("Not started", checked: true)
          expect(page).to have_field("Invalidated", checked: true)
          expect(page).to have_field("In assessment", checked: true)
          expect(page).to have_field("Awaiting determination", checked: true)
          expect(page).to have_field("To be reviewed", checked: true)
        end
      end

      it "Only Planning Applications that are in_assessment are present when filtered" do
        click_on "Filters"
        uncheck "Not started"
        uncheck "Invalidated"
        uncheck "Awaiting determination"
        uncheck "To be reviewed"
        uncheck "Prior approval"
        click_button "Apply filters"

        within(selected_govuk_tab) do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
          expect(page).not_to have_link(prior_approval_not_started.reference)
          expect(page).not_to have_link(prior_approval_in_assessment.reference)
        end
      end

      it "Only Planning Applications that are awaiting_determination are present when filtered" do
        click_on "Filters"
        uncheck "Not started"
        uncheck "Invalidated"
        uncheck "In assessment"
        uncheck "To be reviewed"
        uncheck "Prior approval"
        click_button "Apply filters"

        within(selected_govuk_tab) do
          expect(page).to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_1.reference)
          expect(page).not_to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
          expect(page).not_to have_link(prior_approval_not_started.reference)
          expect(page).not_to have_link(prior_approval_in_assessment.reference)
        end
      end

      it "Only Planning Applications that are in assessment and prior approval are present when filtered" do
        click_on "Filters"
        uncheck "Not started"
        uncheck "Invalidated"
        uncheck "To be reviewed"
        uncheck "Awaiting determination"
        uncheck "Lawfulness certificate"
        click_button "Apply filters"

        within(selected_govuk_tab) do
          expect(page).not_to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_1.reference)
          expect(page).not_to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
          expect(page).not_to have_link(prior_approval_not_started.reference)
          expect(page).to have_link(prior_approval_in_assessment.reference)
        end

        expect(current_url).to include(
          "query=&application_type%5B%5D=&application_type%5B%5D=prior_approval&application_type%5B%5D=planning_permission&application_type%5B%5D=pre_application&application_type%5B%5D=other&status%5B%5D=&status%5B%5D=in_assessment#all"
        )
      end

      it "Only Planning Applications that are prior approval are present when filtered" do
        click_on "Filters"
        uncheck "Lawfulness certificate"
        click_button "Apply filters"

        within(selected_govuk_tab) do
          expect(page).not_to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_1.reference)
          expect(page).not_to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
          expect(page).to have_link(prior_approval_not_started.reference)
          expect(page).to have_link(prior_approval_in_assessment.reference)
        end

        expect(current_url).to include(
          "query=&application_type%5B%5D=&application_type%5B%5D=prior_approval&application_type%5B%5D=planning_permission&application_type%5B%5D=pre_application&application_type%5B%5D=other&status%5B%5D=&status%5B%5D=not_started&status%5B%5D=invalidated&status%5B%5D=in_assessment&status%5B%5D=awaiting_determination&status%5B%5D=to_be_reviewed#all"
        )
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
          visit "/"
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
          visit "/planning_applications?view=all"
          click_link("Live applications")

          within(selected_govuk_tab) do
            expect(page).to have_content("Live applications")
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
          visit "/planning_applications?view=mine"

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

    context "when a planning application is pending" do
      let!(:planning_application) do
        create(
          :planning_application,
          :pending,
          local_authority: default_local_authority,
          address_1: "Pending lane"
        )
      end

      it "does not display the application" do
        click_link "View all applications"
        expect(page).not_to have_content("Pending lane")
      end
    end

    context "when there are prior approval planning applications" do
      let!(:planning_application_not_started) do
        create(
          :planning_application,
          :not_started,
          :ldc_proposed,
          local_authority: default_local_authority,
          application_type: application_type_ldc_proposed
        )
      end

      let!(:planning_application_prior_approval) do
        create(
          :planning_application,
          :not_started,
          :prior_approval,
          local_authority: default_local_authority,
          application_type: application_type_prior_approval
        )
      end

      before do
        visit "/"
      end

      it "sorts planning first" do
        within(selected_govuk_tab) do
          within(".govuk-table.planning-applications-table") do
            within(".govuk-table__head") do
              within(all(".govuk-table__row").first) do
                expect(page).to have_content("Application number")
                expect(page).to have_content("Site address")
                expect(page).to have_content("Expiry date")
                expect(page).to have_content("Days")
                expect(page).to have_content("Status")
              end
            end

            within(".govuk-table__body") do
              rows = page.all(".govuk-table__row")

              within(rows[0]) do
                cells = page.all(".govuk-table__cell")

                within(cells[0]) do
                  expect(page).to have_content(/^\d{2}-\d{5}-PA1A$/)
                end
                within(cells[4]) do
                  expect(page).to have_content("Not started")
                end
              end

              within(rows[1]) do
                cells = page.all(".govuk-table__cell")

                within(cells[0]) do
                  expect(page).to have_content(/^\d{2}-\d{5}-LDCP$/)
                end
                within(cells[4]) do
                  expect(page).to have_content("Not started")
                end
              end

              within(rows[2]) do
                cells = page.all(".govuk-table__cell")

                within(cells[0]) do
                  expect(page).to have_content(/^\d{2}-\d{5}-LDCP$/)
                end
                within(cells[4]) do
                  expect(page).to have_content("In assessment")
                end
              end

              within(rows[3]) do
                cells = page.all(".govuk-table__cell")

                within(cells[0]) do
                  expect(page).to have_content(/^\d{2}-\d{5}-LDCP$/)
                end
                within(cells[4]) do
                  expect(page).to have_content("In assessment")
                end
              end

              within(rows[4]) do
                cells = page.all(".govuk-table__cell")

                within(cells[0]) do
                  expect(page).to have_content(/^\d{2}-\d{5}-LDCP$/)
                end
                within(cells[4]) do
                  expect(page).to have_content("Awaiting determination")
                end
              end
            end
          end
        end
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

        within(selected_govuk_tab) do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).to have_link(other_assessor_planning_application.reference)
        end
      end

      it "An assessor can click back to view only its own applications" do
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
      visit "/"
    end

    context "when planning application is to be reviewed" do
      before do
        create(
          :planning_application,
          :to_be_reviewed,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit "/"

        expect(page).to have_content(
          "Reviewer requests 1 application "
        )
      end
    end

    context "when multiple planning applications are to be reviewed" do
      before do
        create_list(
          :planning_application,
          2,
          :to_be_reviewed,
          local_authority: default_local_authority
        )
      end

      it "renders alert message" do
        visit "/"

        expect(page).to have_content(
          "Reviewer requests 2 applications "
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
        expect(page).to have_link "Live applications"
        expect(page).to have_text "Closed"
      end

      click_link "View my applications"

      within(:planning_applications_status_tab) do
        expect(page).to have_link "Your live applications"
        expect(page).to have_link "Closed"
      end
    end

    it "Only Planning Applications that are owned by this user are present in this tab" do
      within("#all") do
        expect(page).to have_link(reviewer_planning_application_started.reference)
        expect(page).not_to have_link(planning_application_started.reference)
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
