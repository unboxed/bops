# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add heads of terms" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority: default_local_authority, api_user:)
  end

  before do
    Current.user = assessor
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
    click_link "Check and assess"
  end

  context "when planning application is planning permission" do
    it "you can add new heads of terms" do
      within("#add-heads-of-terms") do
        expect(page).to have_content "Not started"
        click_link "Add heads of terms"
      end

      check "Car free development"
      within("#heads-of-term-terms-attributes-0--destroy-conditional") do
        fill_in "Enter detail", with: "No cars"
      end

      check "Highway and public transport"
      within("#heads-of-term-terms-attributes-2--destroy-conditional") do
        fill_in "Enter detail", with: "Wider roads"
      end

      click_link "Add term"

      within("#other-terms") do
        fill_in "Enter a title", with: "Term 3"
        fill_in "Enter detail", with: "Detail 3"
      end

      click_button "Confirm and send to applicant"

      expect(page).to have_content "Heads of terms successfully updated and sent to applicant"

      within("#add-heads-of-terms") do
        expect(page).to have_content "In progress"
        click_link "Add heads of terms"
      end

      within("tr", text: "Car free development") do
        expect(page).to have_content "Awaiting response"
      end

      within("tr", text: "Highway and public transport") do
        expect(page).to have_content "Awaiting response"
      end

      within("tr", text: "Term 3") do
        expect(page).to have_content "Awaiting response"
      end
    end

    it "you can save and come back" do
      within("#add-heads-of-terms") do
        expect(page).to have_content "Not started"
        click_link "Add heads of terms"
      end

      check "Car free development"
      within("#heads-of-term-terms-attributes-0--destroy-conditional") do
        fill_in "Enter detail", with: "No cars"
      end

      check "Highway and public transport"
      within("#heads-of-term-terms-attributes-2--destroy-conditional") do
        fill_in "Enter detail", with: "Wider roads"
      end

      click_button "Save and come back later"

      expect(page).to have_content "Heads of terms successfully saved"

      within("#add-heads-of-terms") do
        expect(page).to have_content "In progress"
        click_link "Add heads of terms"
      end

      within("#heads-of-term-terms-attributes-2--destroy-conditional") do
        fill_in "Enter detail", with: "Even wider roads"
      end

      click_link "Add term"

      within("#other-terms") do
        fill_in "Enter a title", with: "Term 3"
        fill_in "Enter detail", with: "Detail 3"
      end

      click_button "Confirm and send to applicant"

      expect(page).to have_content "Heads of terms successfully updated and sent to applicant"

      within("#add-heads-of-terms") do
        expect(page).to have_content "In progress"
        click_link "Add heads of terms"
      end

      within("tr", text: "Car free development") do
        expect(page).to have_content "Awaiting response"
      end

      within("tr", text: "Highway and public transport") do
        expect(page).to have_content "Awaiting response"
      end

      within("tr", text: "Term 3") do
        expect(page).to have_content "Awaiting response"
      end
    end

    it "you can edit terms once they've been rejected" do
      planning_application.heads_of_term.update(public: true)
      term1 = create(:term, title: "Title 1", heads_of_term: planning_application.heads_of_term)
      term1.current_validation_request.update(state: "closed", approved: false, rejection_reason: "Typo", notified_at: 1.day.ago, closed_at: Time.zone.now)
      create(:review, owner: planning_application.heads_of_term)

      term2 = create(:term, title: "Title 2", heads_of_term: planning_application.heads_of_term)
      term2.current_validation_request.update(state: "closed", approved: true, notified_at: 1.day.ago, closed_at: Time.zone.now)

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"

      click_link "Add heads of terms"

      expect(page).not_to have_content("Save and mark as complete")

      within("tr", text: term1.title) do
        expect(page).to have_content "Typo"
        expect(page).to have_content "Rejected"
        expect(page).to have_link(
          "Update term",
          href: "/planning_applications/#{planning_application.id}/assessment/heads_of_terms/#{term1.id}/edit"
        )
      end

      within("tr", text: term2.title) do
        expect(page).to have_content "Accepted"
      end

      click_link "Update term"

      within(:css, "#other-terms .term:nth-of-type(1)") do
        fill_in "Enter a title", with: "new title"
        fill_in "Enter detail", with: "Custom detail 1"
      end

      click_button "Confirm and send to applicant"

      click_link "Add heads of terms"

      expect(page).to have_content "new title"

      within("tr", text: "new title") do
        expect(page).to have_content "Awaiting response"
        expect(page).to have_link(
          "Cancel",
          href: "/planning_applications/#{planning_application.id}/validation/validation_requests/#{term1.current_validation_request.id}/cancel_confirmation"
        )
      end

      within("tr", text: term2.title) do
        expect(page).to have_content "Accepted"
      end
    end

    it "you can cancel terms" do
      planning_application.heads_of_term.update(public: true)
      term1 = create(:term, title: "Title 1", heads_of_term: planning_application.heads_of_term)
      create(:review, owner: planning_application.heads_of_term)

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"

      click_link "Add heads of terms"

      within("tr", text: term1.title) do
        expect(page).to have_content "Awaiting response"
        expect(page).to have_link(
          "Cancel",
          href: "/planning_applications/#{planning_application.id}/validation/validation_requests/#{term1.current_validation_request.id}/cancel_confirmation"
        )
      end

      click_link "Cancel"

      fill_in "Explain to the applicant why this request is being cancelled", with: "Made a typo"

      click_button "Confirm cancellation"

      expect(page).to have_content "Heads of term request successfully cancelled"

      within("tr", text: "Heads of terms") do
        expect(page).to have_content "Made a typo"
      end
    end

    it "shows errors" do
      click_link "Add heads of terms"

      check "Car free development"
      within("#heads-of-term-terms-attributes-0--destroy-conditional") do
        fill_in "Enter a title", with: ""
        fill_in "Enter detail", with: ""
      end

      click_button "Confirm and send to applicant"

      expect(page).to have_content "Enter the title of this term"
      expect(page).to have_content "Enter the detail of this term"

      check "Car free development"
      within("#heads-of-term-terms-attributes-0--destroy-conditional") do
        fill_in "Enter a title", with: "Car free development"
        fill_in "Enter detail", with: "No cars"
      end

      click_link "+ Add term"

      click_button "Confirm and send to applicant"

      expect(page).to have_content "Enter the title of this term"
      expect(page).to have_content "Enter the detail of this term"
    end

    context "when marking the task as complete" do
      it "you can do it if all requests are approved" do
        planning_application.heads_of_term.update(public: true)
        term1 = create(:term, title: "Title 1", heads_of_term: planning_application.heads_of_term)
        term1.current_validation_request.update(state: "closed", approved: false, rejection_reason: "Typo", notified_at: 1.day.ago, closed_at: Time.zone.now)
        create(:review, owner: planning_application.heads_of_term)

        term2 = create(:term, title: "Title 2", heads_of_term: planning_application.heads_of_term)
        term2.current_validation_request.update(state: "closed", approved: true, notified_at: 1.day.ago, closed_at: Time.zone.now)

        visit "/planning_applications/#{planning_application.id}"
        click_link "Check and assess"

        within("#add-heads-of-terms") do
          expect(page).to have_content "Updated"
          click_link "Add heads of terms"
        end

        expect(page).not_to have_content("Save and mark as complete")

        term1.current_validation_request.update(approved: true)

        visit "/planning_applications/#{planning_application.id}"
        click_link "Check and assess"

        click_link "Add heads of terms"

        click_button "Save and mark as complete"

        within("#add-heads-of-terms") do
          expect(page).to have_content "Complete"

          click_link "Add heads of terms"
        end

        expect(page).not_to have_content("Save and mark as complete")
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
