# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add pre-commencement conditions" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, :with_condition_set, local_authority: default_local_authority, api_user:, decision: "granted")
  end

  def pre_commencement_conditions
    Condition.joins(:condition_set).where(condition_set: {pre_commencement: true})
  end

  before do
    Current.user = assessor
    travel_to(Time.zone.local(2024, 4, 17, 12, 30))
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
    click_link "Check and assess"
  end

  context "when planning application is planning permission" do
    it "you can add pre-commencement conditions and confirm to send" do
      within("#add-pre-commencement-conditions") do
        expect(page).to have_content "Not started"
        click_link "Add pre-commencement conditions"
      end

      expect(page).to have_selector("h1", text: "Add pre-commencement conditions")

      find("span", text: "Add new pre-commencement condition").click
      expect(page).to have_selector("h2", text: "Add a new pre-commencement condition")

      click_button "Add pre-commencement condition"
      expect(page).to have_selector("[role=alert] li", text: "Enter the title of this condition")
      expect(page).to have_selector("[role=alert] li", text: "Enter the text of this condition")
      expect(page).to have_selector("[role=alert] li", text: "Enter the reason for this condition")

      fill_in "Enter title", with: "Title 1"
      fill_in "Enter condition", with: "Custom condition 1"
      fill_in "Enter reason", with: "Custom reason 1"
      click_button "Add pre-commencement condition"

      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement condition has been successfully added")

      find("span", text: "Add new pre-commencement condition").click
      fill_in "Enter title", with: "Title 2"
      fill_in "Enter condition", with: "Custom condition 2"
      fill_in "Enter reason", with: "Custom reason 2"
      click_button "Add pre-commencement condition"

      within("#condition_#{pre_commencement_conditions.first.id}") do
        expect(page).to have_selector("span", text: "Condition 1")
        expect(page).to have_selector("h2", text: "Title 1")
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
        expect(page).to have_selector("p", text: "Custom condition 1")
        expect(page).to have_selector("p", text: "Custom reason 1")

        expect(page).to have_link("Remove")
        expect(page).to have_link("Update condition")
      end

      within("#condition_#{pre_commencement_conditions.second.id}") do
        expect(page).to have_selector("span", text: "Condition 2")
        expect(page).to have_selector("h2", text: "Title 2")
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
        expect(page).to have_selector("p", text: "Custom condition 2")
        expect(page).to have_selector("p", text: "Custom reason 2")
      end

      click_button "Confirm and send to applicant"
      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement conditions have been confirmed and sent to the applicant")

      within("#condition_#{pre_commencement_conditions.first.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        expect(page).to have_selector("p", text: "Sent on 17 April 2024 12:30")
        expect(page).to have_link("Cancel")

        expect(page).not_to have_link("Update condition")
        expect(page).not_to have_link("Remove")
      end

      within("#condition_#{pre_commencement_conditions.second.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        expect(page).to have_selector("p", text: "Sent on 17 April 2024 12:30")
      end

      click_link "Back"
      within("#add-pre-commencement-conditions") do
        expect(page).to have_content "Completed"
        click_link "Add pre-commencement conditions"
      end
    end

    it "you can save pre-commencement conditions and confirm to send" do
      within("#add-pre-commencement-conditions") do
        expect(page).to have_content "Not started"
        click_link "Add pre-commencement conditions"
      end

      expect(page).to have_selector("h1", text: "Add pre-commencement conditions")

      find("span", text: "Add new pre-commencement condition").click

      click_button "Add pre-commencement condition"

      fill_in "Enter title", with: "Title 1"
      fill_in "Enter condition", with: "Custom condition 1"
      fill_in "Enter reason", with: "Custom reason 1"
      click_button "Add pre-commencement condition"

      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement condition has been successfully added")

      within("#condition_#{pre_commencement_conditions.first.id}") do
        expect(page).to have_selector("span", text: "Condition 1")
        expect(page).to have_selector("h2", text: "Title 1")
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
        expect(page).to have_selector("p", text: "Custom condition 1")
        expect(page).to have_selector("p", text: "Custom reason 1")
      end

      click_button "Save and come back later"
      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement conditions have been successfully saved")

      within("#add-pre-commencement-conditions") do
        expect(page).to have_content "In progress"
        click_link "Add pre-commencement conditions"
      end

      within("#condition_#{pre_commencement_conditions.first.id}") do
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
      end

      click_button "Confirm and send to applicant"

      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement conditions have been confirmed and sent to the applicant")

      within("#condition_#{pre_commencement_conditions.first.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        expect(page).to have_selector("p", text: "Sent on 17 April 2024 12:30")
        expect(page).to have_link("Cancel")

        expect(page).not_to have_link("Update condition")
        expect(page).not_to have_link("Remove")
      end

      find("span", text: "Add new pre-commencement condition").click
      fill_in "Enter title", with: "Title 2"
      fill_in "Enter condition", with: "Custom condition 2"
      fill_in "Enter reason", with: "Custom reason 2"
      click_button "Add pre-commencement condition"

      click_button "Save and come back later"
      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement conditions have been successfully saved")

      within("#add-pre-commencement-conditions") do
        expect(page).to have_content "In progress"
        click_link "Add pre-commencement conditions"
      end

      within("#condition_#{pre_commencement_conditions.first.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
      end

      within("#condition_#{pre_commencement_conditions.second.id}") do
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
      end

      click_button "Confirm and send to applicant"

      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement conditions have been confirmed and sent to the applicant")

      within("#condition_#{pre_commencement_conditions.second.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
      end
    end

    it "you can edit conditions once they've been rejected" do
      condition1 = create(:condition, :other, title: "Title 1", condition_set: planning_application.pre_commencement_condition_set)
      travel_to(Time.zone.local(2024, 4, 17, 13, 30)) do
        create(:pre_commencement_condition_validation_request, owner: condition1, planning_application:, state: "closed", approved: false, rejection_reason: "Typo", notified_at: 1.day.ago)
      end
      create(:review, owner: condition1.condition_set)

      condition2 = create(:condition, :other, title: "Title 2", condition_set: condition1.condition_set)
      travel_to(Time.zone.local(2024, 4, 17, 13, 30)) do
        create(:pre_commencement_condition_validation_request, owner: condition2, planning_application:, state: "closed", approved: true, notified_at: 1.day.ago)
      end
      create(:review, owner: condition2.condition_set)

      travel_to(Time.zone.local(2024, 4, 17, 14, 30))
      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"
      click_link "Add pre-commencement conditions"

      within("#condition_#{condition1.id}") do
        expect(page).to have_selector("p strong.govuk-tag", text: "Rejected")
        expect(page).to have_selector("p", text: "Typo")
        expect(page).to have_selector("p", text: "Sent on: 17 April 2024 13:30")
        expect(page).to have_link(
          "Update condition",
          href: "/planning_applications/#{planning_application.id}/assessment/pre_commencement_conditions/#{condition1.id}/edit"
        )
      end

      within("#condition_#{condition2.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Accepted")
        expect(page).to have_link(
          "Update condition",
          href: "/planning_applications/#{planning_application.id}/assessment/pre_commencement_conditions/#{condition2.id}/edit"
        )
      end

      within("#condition_#{condition1.id}") do
        click_link "Update condition"
      end

      fill_in "Enter title", with: "New title"
      fill_in "Enter condition", with: "New condition"
      fill_in "Enter reason", with: "New reason"
      click_button "Update pre-commencement condition"

      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement condition was successfully updated")

      within("#condition_#{condition1.id}") do
        expect(page).to have_selector("h2", text: "New title")
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
        expect(page).to have_selector("p", text: "New condition")
        expect(page).to have_selector("p", text: "New reason")
      end

      click_button "Confirm and send to applicant"
      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement conditions have been confirmed and sent to the applicant")
    end

    it "you can cancel conditions" do
      condition1 = create(:condition, :other, title: "Title 1", condition_set: planning_application.pre_commencement_condition_set)
      travel_to(Time.zone.local(2024, 4, 17, 13, 30)) do
        create(:pre_commencement_condition_validation_request, owner: condition1, planning_application:, state: "open", notified_at: 1.day.ago)
      end
      create(:review, owner: condition1.condition_set)

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"
      click_link "Add pre-commencement conditions"

      within("#condition_#{condition1.id}") do
        expect(page).to have_selector("h2", text: "Title 1")
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        click_link "Cancel"
      end

      fill_in "Explain to the applicant why this request is being cancelled", with: "Made a typo"

      click_button "Confirm cancellation"
      expect(page).to have_content "Pre-commencement condition agreement request was successully cancelled"

      click_link "Application"
      click_link "Check and assess"
      click_link "Add pre-commencement conditions"

      within("#condition_#{condition1.id}") do
        expect(page).to have_selector("h2", text: "Title 1")
        expect(page).to have_selector("p strong.govuk-tag", text: "Cancelled")

        expect(page).not_to have_link("Cancel")
        expect(page).not_to have_link("Update condition")
        expect(page).not_to have_link("Remove")
      end
    end

    it "I can remove a condition only if it has not been sent to the applicant" do
      click_link "Add pre-commencement conditions"
      find("span", text: "Add new pre-commencement condition").click

      fill_in "Enter title", with: "Title 1"
      fill_in "Enter condition", with: "Custom condition 1"
      fill_in "Enter reason", with: "Custom reason 1"
      click_button "Add pre-commencement condition"

      within("#condition_#{Condition.last.id}") do
        expect(page).to have_selector("h2", text: "Title 1")

        accept_confirm(text: "Are you sure?") do
          click_link("Remove")
        end
      end

      expect(page).to have_selector("[role=alert] p", text: "Pre-commencement condition was successfully removed")
      expect(page).not_to have_selector("h2", text: "Title 1")

      find("span", text: "Add new pre-commencement condition").click

      fill_in "Enter title", with: "Another title"
      fill_in "Enter condition", with: "Another condition"
      fill_in "Enter reason", with: "Another reason"
      click_button "Add pre-commencement condition"
      click_button "Confirm and send to applicant"

      within("#condition_#{Condition.last.id}") do
        expect(page).to have_selector("h2", text: "Another title")

        expect(page).not_to have_link("Remove")
      end
    end

    it "shows conditions on the decision notice" do
      create(:recommendation, :assessment_in_progress, planning_application:)
      condition = create(:condition, :other, condition_set: planning_application.pre_commencement_condition_set, title: "title 1")
      create(:pre_commencement_condition_validation_request, owner: condition, approved: true, state: "closed")

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"
      click_link "Review and submit recommendation"

      expect(page).to have_content "Pre-commencement conditions"
      expect(page).to have_content condition.title
      expect(page).to have_content condition.text
      expect(page).to have_content condition.reason
    end
  end

  context "when changing the list position" do
    let(:condition_set) { planning_application.pre_commencement_condition_set }
    let!(:condition_one) { create(:condition, condition_set:, title: "Title 1", text: "Text 1") }
    let!(:condition_two) { create(:condition, :other, condition_set:, title: "Title 2", text: "Text 2") }
    let!(:condition_three) { create(:condition, condition_set:, title: "Title 3", text: "Text 3") }

    it "I can drag and drop to sort the pre-commencement conditions" do
      click_link "Add pre-commencement conditions"
      expect(page).to have_selector("p", text: "Drag and drop pre-commencement conditions to change the order that they appear in the decision notice.")

      condition_one_handle = find("li.sortable-list", text: "Title 1")
      condition_two_handle = find("li.sortable-list", text: "Title 2")
      condition_three_handle = find("li.sortable-list", text: "Title 3")

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Condition 1")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Condition 2")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Condition 3")
        expect(page).to have_selector("h2", text: "Title 3")
      end

      condition_one_handle.drag_to(condition_two_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Condition 1")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Condition 2")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Condition 3")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      expect(condition_one.reload.position).to eq(2)
      expect(condition_two.reload.position).to eq(1)
      expect(condition_three.reload.position).to eq(3)

      condition_one_handle.drag_to(condition_three_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Condition 1")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Condition 2")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Condition 3")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      expect(condition_one.reload.position).to eq(3)
      expect(condition_two.reload.position).to eq(1)
      expect(condition_three.reload.position).to eq(2)

      condition_three_handle.drag_to(condition_two_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Condition 1")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Condition 2")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Condition 3")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      expect(condition_one.reload.position).to eq(3)
      expect(condition_two.reload.position).to eq(2)
      expect(condition_three.reload.position).to eq(1)

      click_link "Back"
      click_link "Add pre-commencement conditions"

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Condition 1")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Condition 2")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Condition 3")
        expect(page).to have_selector("h2", text: "Title 1")
      end

      # Check the correct order on decision notice
      click_button "Confirm and send to applicant"
      condition_set.validation_requests.each { |vr| vr.update(approved: true) }
      create(:recommendation, :assessment_in_progress, planning_application:)
      click_link "Back"
      click_link "Review and submit recommendation"

      within("#pre-commencement-conditions-list") do
        expect(page).to have_selector("li:nth-of-type(1)", text: "Title 3")
        expect(page).to have_selector("li:nth-of-type(2)", text: "Title 2")
        expect(page).to have_selector("li:nth-of-type(3)", text: "Title 1")
      end
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
