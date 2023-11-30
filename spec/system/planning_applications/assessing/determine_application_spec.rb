# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment" do
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
      let!(:reviewer) do
        create(
          :user,
          :reviewer,
          local_authority: default_local_authority,
          name: "Alice Smith"
        )
      end

      before do
        create(
          :recommendation,
          planning_application:,
          reviewer:
        )

        travel_to Time.zone.local(2024, 2, 1)
        sign_in(reviewer)
        visit "/planning_applications/#{planning_application.id}"
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
          expect(find_by_id("planning_application_determination_date_3i").value).to eq("1")
          expect(find_by_id("planning_application_determination_date_2i").value).to eq("2")
          expect(find_by_id("planning_application_determination_date_1i").value).to eq("2024")

          # Enter date in the future
          fill_in "Day", with: "03"
          fill_in "Month", with: "12"
          fill_in "Year", with: "2024"
        end

        click_button("Publish determination")

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

        click_button("Publish determination")

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

        expect(page).to have_content("Town and Country Planning Act 1990 (as amended): sections 191 and 192")
        expect(page).to have_content("Town and Country Planning (Development Management Procedure) (England) Order 2015 (as amended): Article 39")

        expect(page).to have_content("Jane Smith, Director")

        visit "/planning_applications/#{planning_application.id}"

        # Check latest audit
        click_button "Audit log"

        expect(page).to have_content("Decision Published")
        expect(page).to have_text("Alice Smith")
        expect(page).to have_text("1 February 2024 at 00:00")

        expect(page).to have_text(
          "Application granted on 2 January 2024 (manually inputted date)"
        )

        click_link("View all audits")

        # Check audit logs
        within("#audit_#{Audit.last.id}") do
          expect(page).to have_content("Decision Published")
          expect(page).to have_text("Application granted on 2 January 2024 (manually inputted date)")
          expect(page).to have_text(reviewer.name)
          expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
        end
      end

      it "I can navigate back" do
        click_link("Publish determination")

        click_link("Back")

        expect(page).to have_title "Planning Application"
      end

      context "when open description_change_validation_request" do
        before do
          create(
            :description_change_validation_request,
            :open,
            planning_application:,
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
          click_button("Publish determination")

          expect(page).to have_content("Decision Notice sent to applicant")
        end
      end

      context "when the application is for a prior approval" do
        let(:application_type) { create(:application_type, :prior_approval) }
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination,
            :from_planx_prior_approval,
            application_type:,
            local_authority: default_local_authority,
            decision: "granted")
        end

        it "lists different legislation in the decision notice" do
          click_link("Publish determination")

          within("#determination-date") do
            # Enter date today
            fill_in "Day", with: "2"
            fill_in "Month", with: "1"
            fill_in "Year", with: "2024"
          end

          click_button("Publish determination")

          click_link("View decision notice")
          expect(page).to have_content("Town and Country Planning Act 1990 (as amended)")
          expect(page).not_to have_content("Town and Country Planning (Development Management Procedure) (England) Order 2015 (as amended): Article 39")
        end
      end

      context "when there is a required site notice without a displayed at date" do
        let(:application_type) { create(:application_type, :planning_permission) }
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination,
            application_type:,
            local_authority: default_local_authority,
            decision: "granted")
        end

        let!(:site_notice) do
          create(:site_notice, planning_application:, displayed_at: nil)
        end

        it "displays a warning when trying to determine an application" do
          click_link("Publish determination")
          click_button("Publish determination")

          within(".govuk-notification-banner--alert") do
            expect(page).to have_content("Confirm the site notice displayed at date before determining the application")
            expect(page).to have_link(
              "Confirm the site notice displayed at date", href: edit_planning_application_site_notice_path(planning_application, site_notice)
            )
          end
        end
      end

      context "when there is a required press notice without a published at date" do
        let(:application_type) { create(:application_type, :planning_permission) }
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination,
            application_type:,
            local_authority: default_local_authority,
            decision: "granted")
        end

        let!(:press_notice) do
          create(:press_notice, :required, planning_application:, published_at: nil)
        end

        it "displays a warning when trying to determine an application" do
          click_link("Publish determination")
          click_button("Publish determination")

          within(".govuk-notification-banner--alert") do
            expect(page).to have_content("Confirm the press notice published at date before determining the application")
            expect(page).to have_link(
              "Confirm the press notice published at date", href: "/planning_applications/#{planning_application.id}/press_notice/confirmation"
            )
          end
        end
      end

      context "when the decision is for a householder application" do
        let(:application_type) { create(:application_type, :planning_permission) }
        let!(:planning_application) do
          create(:planning_application, :awaiting_determination,
            :from_planx_prior_approval,
            application_type:,
            local_authority: default_local_authority,
            decision: "granted")
        end

        before do
          click_link("Publish determination")

          within("#determination-date") do
            # Enter date today
            fill_in "Day", with: "2"
            fill_in "Month", with: "1"
            fill_in "Year", with: "2024"
          end

          click_button("Publish determination")
        end

        it "lists different legislation in the decision notice" do
          click_link("View decision notice")
          expect(page).to have_content("Town and Country Planning Act 1990 (as amended)")
          expect(page).to have_content("Town and Country Planning (Development Management Procedure) (England) Order 2015")
          expect(page).not_to have_content("sections 191 and 192")
          expect(page).not_to have_content("Article 39")
        end
      end
    end

    context "when I'm signed in as an assessor" do
      let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

      before do
        sign_in(assessor)
        visit "/planning_applications/#{planning_application.id}"
      end

      it "I cannot determine the application" do
        expect(page).not_to have_link("Publish determination")
      end
    end
  end
end
