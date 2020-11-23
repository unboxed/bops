# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Planning Application index page", type: :system do
  let(:local_authority) { create :local_authority }
  let!(:planning_application_1) { create :planning_application, local_authority: local_authority }
  let!(:planning_application_2) { create :planning_application, local_authority: local_authority }
  let!(:planning_application_started) { create :planning_application, :awaiting_determination, local_authority: local_authority }
  let!(:planning_application_completed) { create :planning_application, :determined, local_authority: local_authority }
  let(:assessor) { create :user, :assessor, local_authority: local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: local_authority }


  context "as an assessor" do
    before do
      sign_in assessor
      visit root_path
    end

    context "viewing tabs" do
      scenario "Planning Application status bar is present" do
        within(:planning_applications_status_tab) do
          expect(page).to have_link "In assessment"
          expect(page).to have_link "Awaiting manager's determination"
          expect(page).to have_link "Determined"
        end
      end

      scenario "Only Planning Applications that are in_assessment are present in this tab" do
        within("#in_assessment") do
          expect(page).to have_text("In assessment")
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
        end
      end

      scenario "Only Planning Applications that are awaiting_determination are present in this tab" do
        click_link "Awaiting manager's determination"

        within("#awaiting_determination") do
          expect(page).to have_text("Awaiting manager's determination")
          expect(page).to have_link(planning_application_started.reference)
          expect(page).not_to have_link(planning_application_1.reference)
          expect(page).not_to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_completed.reference)
        end
      end

      scenario "Only Planning Applications that are determined are present in this tab" do
        click_link "Determined"

        within("#determined") do
          expect(page).to have_text("Determined")
          expect(page).to have_link(planning_application_completed.reference)
          expect(page).not_to have_link(planning_application_1.reference)
          expect(page).not_to have_link(planning_application_2.reference)
          expect(page).not_to have_link(planning_application_started.reference)
        end
      end

      scenario "Breadcrumbs are not displayed" do
        expect(find(".govuk-breadcrumbs__list").text).to be_empty
      end

      scenario "User can log out from index page" do
        click_button "Log out"

        expect(page).to have_current_path(/sign_in/)
        expect(page).to have_content("You need to sign in or sign up before continuing.")
      end
    end

    context "restricted views" do
      let!(:second_assessor) { create :user, :assessor, local_authority: local_authority }
      let!(:other_assessor_planning_application) { create :planning_application, user_id: second_assessor.id, local_authority: local_authority }

      scenario "On login, assessor gets redirected to a view with its own and unassigned Planning Applications" do
        within("#in_assessment") do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).not_to have_link(other_assessor_planning_application.reference)
        end
      end

      scenario "An assessor can click a button to view all applications" do
        click_on "View all applications"

        within("#in_assessment") do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).to have_link(other_assessor_planning_application.reference)
        end
      end

      scenario "An aassessor can click back to view only its own applications" do
        click_on "View all applications"

        click_on "View my applications"

        within("#in_assessment") do
          expect(page).to have_link(planning_application_1.reference)
          expect(page).to have_link(planning_application_2.reference)
          expect(page).not_to have_link(other_assessor_planning_application.reference)
        end
      end

      scenario "Applications in a determined state belonging to other assessors are also not visible on login" do
        other_assessor_planning_application.update(status: "determined", determined_at: Time.current)
        click_link "Determined"

        within("#determined") do
          expect(page).not_to have_link(other_assessor_planning_application.reference)
        end

        click_on "View all applications"
        click_link "Determined"

        within("#determined") do
          expect(page).to have_link(other_assessor_planning_application.reference)
        end
      end
    end
  end

  context "as an reviewer" do
    before do
      sign_in reviewer
      visit root_path
    end

    scenario "Planning Application status bar is present and does not show In Assessment by default" do
      within(:planning_applications_status_tab) do
        expect(page).to have_link "Awaiting manager's determination"
        expect(page).to have_link "Determined"
        expect(page).not_to have_link "In assessment"
      end
    end

    scenario "Reviewer can see applications in assessment status by toggling link" do
      click_link "View all applications"

      within(:planning_applications_status_tab) do
        expect(page).to have_link "Awaiting manager's determination"
        expect(page).to have_link "Determined"
        expect(page).to have_link "In assessment"
      end

      click_link "View assessed applications"

      within(:planning_applications_status_tab) do
        expect(page).to have_link "Awaiting manager's determination"
        expect(page).to have_link "Determined"
        expect(page).not_to have_link "In assessment"
      end
    end

    scenario "Only Planning Applications that are awaiting_determination are present in this tab" do
      click_link "Awaiting manager's determination"

      within("#awaiting_determination") do
        expect(page).to have_text("Awaiting manager's determination")
        expect(page).to have_link(planning_application_started.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_completed.reference)
      end
    end

    scenario "Only Planning Applications that are determined are present in this tab" do
      click_link "Determined"

      within("#determined") do
        expect(page).to have_text("Determined")
        expect(page).to have_link(planning_application_completed.reference)
        expect(page).not_to have_link(planning_application_1.reference)
        expect(page).not_to have_link(planning_application_2.reference)
        expect(page).not_to have_link(planning_application_started.reference)
      end
    end

    scenario "Breadcrumbs are not displayed" do
      expect(find(".govuk-breadcrumbs__list").text).to be_empty
    end

    scenario "User can log out from index page" do
      click_button "Log out"

      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end
end
