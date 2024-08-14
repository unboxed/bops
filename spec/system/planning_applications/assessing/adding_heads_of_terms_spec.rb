# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add heads of terms", type: :system, capybara: true do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority: default_local_authority, api_user:)
  end

  before do
    Current.user = assessor
    travel_to(Time.zone.local(2024, 4, 17, 12, 30))
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  context "when planning application is planning permission" do
    it "you can add new heads of terms" do
      within("#add-heads-of-terms") do
        expect(page).to have_content "Not started"
        click_link "Add heads of terms"
      end

      expect(page).to have_selector("h1", text: "Add heads of terms")
      find("span", text: "Add a new heads of terms").click
      expect(page).to have_selector("h2", text: "Add a new heads of term")

      click_button "Add term"
      expect(page).to have_selector("[role=alert] li", text: "Enter the title of this term")
      expect(page).to have_selector("[role=alert] li", text: "Enter the detail of this term")

      fill_in "Enter title", with: "Title 1"
      fill_in "Enter details", with: "Custom details 1"
      click_button "Add term"

      expect(page).to have_selector("[role=alert] p", text: "Head of terms has been successfully added")

      find("span", text: "Add a new heads of terms").click
      fill_in "Enter title", with: "Title 2"
      fill_in "Enter details", with: "Custom details 2"
      click_button "Add term"

      within("#term_#{Term.first.id}") do
        expect(page).to have_selector("span", text: "Heads of term 1")
        expect(page).to have_selector("h2", text: "Title 1")
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
        expect(page).to have_selector("p", text: "Custom details 1")

        expect(page).to have_link("Remove")
        expect(page).to have_link("Edit")
      end

      within("#term_#{Term.second.id}") do
        expect(page).to have_selector("span", text: "Heads of term 2")
        expect(page).to have_selector("h2", text: "Title 2")
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
        expect(page).to have_selector("p", text: "Custom details 2")
      end

      click_button "Confirm and send to applicant"
      expect(page).to have_selector("[role=alert] p", text: "Head of terms have been confirmed and sent to the applicant")

      within("#term_#{Term.first.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        expect(page).to have_selector("p", text: "Sent on 17 April 2024 12:30")
        expect(page).to have_link("Cancel")

        expect(page).not_to have_link("Edit")
        expect(page).not_to have_link("Remove")
      end

      within("#term_#{Term.second.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        expect(page).to have_selector("p", text: "Sent on 17 April 2024 12:30")
      end

      click_link "Back"
      within("#add-heads-of-terms") do
        expect(page).to have_content "Completed"
        click_link "Add heads of terms"
      end
    end

    it "you can edit terms" do
      term1 = create(:term, title: "Title 1", heads_of_term: planning_application.heads_of_term)
      travel_to(Time.zone.local(2024, 4, 17, 13, 30)) do
        create(:heads_of_terms_validation_request, owner: term1, planning_application:, state: "closed", approved: false, rejection_reason: "Typo", notified_at: 1.day.ago)
      end
      create(:review, owner: term1.heads_of_term)

      term2 = create(:term, title: "Title 2", heads_of_term: term1.heads_of_term)
      travel_to(Time.zone.local(2024, 4, 17, 13, 30)) do
        create(:heads_of_terms_validation_request, owner: term2, planning_application:, state: "closed", approved: true, notified_at: 1.day.ago)
      end
      create(:review, owner: term2.heads_of_term)

      travel_to(Time.zone.local(2024, 4, 17, 14, 30))
      visit "/planning_applications/#{planning_application.reference}"
      click_link "Check and assess"
      click_link "Add heads of terms"

      within("#term_#{term1.id}") do
        expect(page).to have_selector("p strong.govuk-tag", text: "Rejected")
        expect(page).to have_selector("p", text: "Typo")
        expect(page).to have_selector("p", text: "Sent on: 17 April 2024 13:30")
        expect(page).to have_link(
          "Edit",
          href: "/planning_applications/#{planning_application.reference}/assessment/terms/#{term1.id}/edit"
        )
      end

      within("#term_#{term2.id}") do
        expect(page).to have_selector(".govuk-tag", text: "Accepted")
        expect(page).to have_link(
          "Edit",
          href: "/planning_applications/#{planning_application.reference}/assessment/terms/#{term2.id}/edit"
        )
      end

      within("#term_#{term1.id}") do
        click_link "Edit"
      end

      fill_in "Enter title", with: "New title"
      fill_in "Enter details", with: "New detail"
      click_button "Update term"

      expect(page).to have_selector("[role=alert] p", text: "Head of terms was successfully updated")

      within("#term_#{term1.id}") do
        expect(page).to have_selector("h2", text: "New title")
        expect(page).to have_selector("p strong.govuk-tag", text: "Not sent")
        expect(page).to have_selector("p", text: "New detail")
      end

      click_button "Confirm and send to applicant"
      expect(page).to have_selector("[role=alert] p", text: "Head of terms have been confirmed and sent to the applicant")
    end

    it "you can cancel terms" do
      term1 = create(:term, title: "Title 1", heads_of_term: planning_application.heads_of_term)
      travel_to(Time.zone.local(2024, 4, 17, 13, 30)) do
        create(:heads_of_terms_validation_request, owner: term1, planning_application:, state: "open", notified_at: 1.day.ago)
      end
      create(:review, owner: planning_application.heads_of_term)

      visit "/planning_applications/#{planning_application.reference}"
      click_link "Check and assess"

      click_link "Add heads of terms"

      within("#term_#{term1.id}") do
        expect(page).to have_selector("h2", text: "Title 1")
        expect(page).to have_selector(".govuk-tag", text: "Awaiting response")
        click_link "Cancel"
      end

      fill_in "Explain to the applicant why this request is being cancelled", with: "Made a typo"

      click_button "Confirm cancellation"
      expect(page).to have_content "Heads of term request successfully cancelled"

      click_link "Application"
      click_link "Check and assess"
      click_link "Add heads of term"

      expect(page).not_to have_selector("p strong.govuk-tag", text: "Cancelled")
    end
  end

  it "I can remove a term only if it has not been sent to the applicant" do
    click_link "Add heads of terms"
    find("span", text: "Add a new heads of terms").click

    fill_in "Enter title", with: "Title 1"
    fill_in "Enter details", with: "Custom details 1"
    click_button "Add term"

    within("#term_#{Term.last.id}") do
      expect(page).to have_selector("h2", text: "Title 1")

      accept_confirm(text: "Are you sure?") do
        click_link("Remove")
      end
    end

    expect(page).to have_selector("[role=alert] p", text: "Head of terms was successfully removed")
    expect(page).not_to have_selector("h2", text: "Title 1")

    find("span", text: "Add a new heads of terms").click

    fill_in "Enter title", with: "Another title"
    fill_in "Enter details", with: "Another detail"
    click_button "Add term"
    click_button "Confirm and send to applicant"

    within("#term_#{Term.last.id}") do
      expect(page).to have_selector("h2", text: "Another title")

      expect(page).not_to have_link("Remove")
    end
  end

  context "when changing the list position" do
    let(:heads_of_term) { planning_application.heads_of_term }
    let!(:term_one) { create(:term, heads_of_term:, title: "Title 1", text: "Text 1", position: 1) }
    let!(:term_two) { create(:term, heads_of_term:, title: "Title 2", text: "Text 2", position: 2) }
    let!(:term_three) { create(:term, heads_of_term:, title: "Title 3", text: "Text 3", position: 3) }

    it "I can drag and drop to sort the heads of terms" do
      click_link "Add heads of term"
      expect(page).to have_selector("p", text: "Drag and drop heads of terms to change the order that they appear in the decision notice.")

      term_one_handle = find("li.sortable-list", text: "Title 1")
      term_two_handle = find("li.sortable-list", text: "Title 2")
      term_three_handle = find("li.sortable-list", text: "Title 3")

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Heads of term 1")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Heads of term 2")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Heads of term 3")
        expect(page).to have_selector("h2", text: "Title 3")
      end

      term_one_handle.drag_to(term_two_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Heads of term 1")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Heads of term 2")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Heads of term 3")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      expect(term_one.reload.position).to eq(2)
      expect(term_two.reload.position).to eq(1)
      expect(term_three.reload.position).to eq(3)

      term_one_handle.drag_to(term_three_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Heads of term 1")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Heads of term 2")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Heads of term 3")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      expect(term_one.reload.position).to eq(3)
      expect(term_two.reload.position).to eq(1)
      expect(term_three.reload.position).to eq(2)

      term_three_handle.drag_to(term_two_handle)

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Heads of term 1")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Heads of term 2")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Heads of term 3")
        expect(page).to have_selector("h2", text: "Title 1")
      end
      expect(term_one.reload.position).to eq(3)
      expect(term_two.reload.position).to eq(2)
      expect(term_three.reload.position).to eq(1)

      click_link "Back"
      click_link "Add heads of terms"

      within("li.sortable-list:nth-of-type(1)") do
        expect(page).to have_selector("span", text: "Heads of term 1")
        expect(page).to have_selector("h2", text: "Title 3")
      end
      within("li.sortable-list:nth-of-type(2)") do
        expect(page).to have_selector("span", text: "Heads of term 2")
        expect(page).to have_selector("h2", text: "Title 2")
      end
      within("li.sortable-list:nth-of-type(3)") do
        expect(page).to have_selector("span", text: "Heads of term 3")
        expect(page).to have_selector("h2", text: "Title 1")
      end
    end
  end
end
