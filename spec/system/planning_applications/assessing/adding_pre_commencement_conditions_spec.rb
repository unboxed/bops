# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add pre-commencement conditions" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, :with_condition_set, local_authority: default_local_authority, api_user:, decision: "granted")
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
    click_link "Check and assess"
  end

  context "when planning application is planning permission" do
    it "you can add pre-commencement conditions" do
      click_link "Add pre-commencement conditions"

      expect(page).to have_content("Add pre-commencement conditions")

      within(:css, "#other-conditions .condition:nth-of-type(1)") do
        fill_in "Enter a title", with: "Title 1"
        fill_in "Enter condition", with: "Custom condition 1"
        fill_in "Enter a reason for this condition", with: "Custom reason 1"
      end

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(2)") do
        fill_in "Enter a title", with: "Title 2"
        fill_in "Enter condition", with: "Custom condition 2"
        fill_in "Enter a reason for this condition", with: "Custom reason 2"
      end

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(3)") do
        fill_in "Enter a title", with: "Title 3"
        fill_in "Enter condition", with: "Custom condition 3"
        fill_in "Enter a reason for this condition", with: "Custom reason 3"
        click_link "Remove condition"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content "Conditions successfully updated"

      within("#add-pre-commencement-conditions") do
        expect(page).to have_content "Completed"
        click_link "Add pre-commencement conditions"
      end

      expect(page).to have_content "Condition 1"
      expect(page).to have_content "Title 1"
      expect(page).to have_content "Condition 2"
      expect(page).to have_content "Title 2"

      within("tr", text: "Title 1") do
        expect(page).to have_content "Not responded"
      end

      within("tr", text: "Title 2") do
        expect(page).to have_content "Not responded"
      end
    end

    it "you can edit conditions once they've been rejected" do
      condition1 = create(:condition, :other, title: "Title 1", condition_set: planning_application.pre_commencement_condition_set)
      create(:pre_commencement_condition_validation_request, condition: condition1, planning_application:, state: "closed", approved: false, rejection_reason: "Typo")

      condition2 = create(:condition, :other, title: "Title 2", condition_set: condition1.condition_set)
      create(:pre_commencement_condition_validation_request, condition: condition2, planning_application:, state: "closed", approved: true)

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"

      click_link "Add pre-commencement conditions"

      within("tr", text: condition1.title) do
        expect(page).to have_content "Typo"
        expect(page).to have_content "Rejected"
        expect(page).to have_link(
          "Update condition",
          href: "/planning_applications/#{planning_application.id}/assessment/conditions/#{condition1.id}/edit?pre_commencement=true"
        )
      end

      within("tr", text: condition2.title) do
        expect(page).to have_content "Approved"
      end

      click_link "Update condition"

      within(:css, "#other-conditions .condition:nth-of-type(1)") do
        fill_in "Enter a title", with: "new title"
        fill_in "Enter condition", with: "Custom condition 1"
        fill_in "Enter a reason for this condition", with: "Custom reason 1"
      end

      click_button "Save and mark as complete"

      click_link "Add pre-commencement conditions"

      expect(page).to have_content "new title"

      within("tr", text: "new title") do
        expect(page).to have_content "Not responded"
        expect(page).to have_link(
          "Cancel",
          href: "/planning_applications/#{planning_application.id}/validation/validation_requests/#{condition1.current_validation_request.id}/cancel_confirmation"
        )
      end

      within("tr", text: condition2.title) do
        expect(page).to have_content "Approved"
      end
    end

    it "you can cancel conditions" do
      condition1 = create(:condition, :other, title: "Title 1", condition_set: planning_application.pre_commencement_condition_set)
      create(:pre_commencement_condition_validation_request, condition: condition1, planning_application:, state: "open")

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"

      click_link "Add pre-commencement conditions"

      within("tr", text: condition1.title) do
        expect(page).to have_content "Not responded"
        expect(page).to have_link(
          "Cancel",
          href: "/planning_applications/#{planning_application.id}/validation/validation_requests/#{condition1.current_validation_request.id}/cancel_confirmation"
        )
      end

      click_link "Cancel"

      fill_in "Explain to the applicant why this request is being cancelled", with: "Made a typo"

      click_button "Confirm cancellation"

      expect(page).to have_content "Pre-commencement condition agreement request was successully cancelled"

      within("tr", text: "Pre-commencement condition") do
        expect(page).to have_content "Made a typo"
      end
    end

    it "shows errors" do
      click_link "Add pre-commencement conditions"

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(1)") do
        fill_in "Enter a title", with: "Title 1"
        fill_in "Enter a reason for this condition", with: "Custom reason 1"
      end

      click_link "+ Add condition"
      within(:css, "#other-conditions .condition:nth-of-type(2)") do
        fill_in "Enter condition", with: "Custom condition 1"
        fill_in "Enter a reason for this condition", with: "Custom reason 1"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content "Enter the text of this condition"
      expect(page).to have_content "Enter the title of this condition"
    end

    it "shows conditions on the decision notice" do
      create(:recommendation, :assessment_in_progress, planning_application:)
      condition = create(:condition, :other, condition_set: planning_application.pre_commencement_condition_set, title: "title 1")

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"
      click_link "Review and submit recommendation"

      expect(page).to have_content "Pre-commencement conditions"
      expect(page).to have_content condition.title
      expect(page).to have_content condition.text
      expect(page).to have_content condition.reason
    end
  end

  xcontext "when planning application is not planning permission" do
    it "you cannot add conditions" do
      type = create(:application_type)
      planning_application.update(application_type: type)

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"

      expect(page).not_to have_content("Add conditions")
    end
  end
end
