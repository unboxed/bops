# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Immunity", type: :system do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:reviewer) { create(:user, :reviewer, local_authority: default_local_authority) }

  context "when not immune" do
    before do
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"
    end

    let(:planning_application) do
      create(:planning_application, :invalidated, validated_at: nil, local_authority: default_local_authority)
    end

    it "returns false from possibly_immune?" do
      expect(planning_application.possibly_immune?).to be false
    end

    it "doesn't mention immunity in the page header" do
      expect(page).not_to have_content("may be immune from enforcement")
    end
  end

  context "when immune" do
    let(:planning_application) do
      create(:planning_application, :invalidated, validated_at: nil, local_authority: default_local_authority)
    end

    before do
      allow_any_instance_of(PlanningApplication).to receive(:possibly_immune?).and_return(true)
      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"
    end

    it "returns true from possibly_immune?" do
      expect(planning_application.possibly_immune?).to be true
    end

    it "mentions immunity in the page header" do
      expect(page).to have_content("may be immune from enforcement")
    end
  end

  context "when there is both an assessment and review for the immunity of an application" do
    let(:planning_application) do
      create(:planning_application, :in_assessment, local_authority: default_local_authority)
    end

    let!(:immunity_detail) { create(:immunity_detail, planning_application:) }

    before do
      create(:evidence_group, :with_document, tag: "utilityBill", missing_evidence: true, missing_evidence_entry: "gaps everywhere", immunity_detail: planning_application.immunity_detail)
      create(:decision, :ldc_granted)
      create(:decision, :ldc_refused)

      sign_in assessor
      visit "/planning_applications/#{planning_application.reference}"
    end

    it "shows the assessment and review stages for immunity", :capybara do
      click_link("Check and assess")
      expect(page).to have_content("Note: application may be immune from enforcement")

      click_link("Evidence of immunity")
      click_button "Utility bills (1)"

      within(open_accordion_section) do
        check "Missing evidence (gap in time)"
        fill_in "List all the gap(s) in time", with: "May 2020"
        fill_in "Add comment", with: "Not good enough"
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Evidence of immunity successfully updated")

      click_link("Immunity/permitted development rights")

      within("#assess-immunity-detail-section") do
        choose "Yes"

        within(".govuk-radios") do
          choose "no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse"
        end

        fill_in "Immunity from enforcement summary", with: "A summary"
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Immunity/permitted development rights response was successfully created")

      click_link "Make draft recommendation"
      within_fieldset("What is your recommendation?") do
        choose "Granted"
      end
      fill_in "State the reasons for your recommendation.", with: "A public comment"
      fill_in "Provide supporting information for your manager.", with: "A private comment"
      click_button "Save and mark as complete"

      click_on("Review and submit recommendation")
      click_on("Submit recommendation")

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}"
      click_link "Review and sign-off"

      click_button "Review evidence of immunity"

      within("#review-immunity-details") do
        choose "Return with comments"
        fill_in "Add a comment", with: "Please re-assess the evidence of immunity"
        click_button "Save and mark as complete"
      end

      expect(page).to have_content("Review immunity details was successfully updated")

      click_button "Review assessment of immunity"

      within("#review-immunity-enforcements") do
        expect(page).to have_content("Assessor decision: Yes")
        expect(page).to have_content("Reason: no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse")
        expect(page).to have_content("Summary: A summary")
      end

      within("#review-immunity-enforcements-form") do
        choose "Return with comments"
        fill_in "Add a comment", with: "Please re-assess immunity enforcement response"
        click_button "Save and mark as complete"
      end

      expect(page).to have_content("Review immunity details was successfully updated for enforcement")

      sign_in(assessor)
      visit "/planning_applications/#{planning_application.reference}"
      click_link("Check and assess")
      click_link("Evidence of immunity")

      # Fill in evidence of immunity again
      expect(page).to have_content("Reviewer comment")
      expect(page).to have_content("Please re-assess the evidence of immunity")

      # Modify evidence group input
      click_button "Utility bills (1)"

      within(open_accordion_section) do
        check "Missing evidence (gap in time)"
        fill_in "List all the gap(s) in time", with: "June 2020"
        fill_in "Add comment", with: "Never good enough"
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Evidence of immunity successfully updated")

      within("#immunity-permitted-development-rights") do
        expect(page).to have_content("To be reviewed")
        click_link("Immunity/permitted development rights")
      end

      expand_span_item("See previous review immunity detail responses")
      expect(page).to have_content("Assessor decision: Yes")
      expect(page).to have_content("Reason: no action is taken within 4 years for an unauthorised change of use to a single dwellinghouse")
      expect(page).to have_content("Summary: A summary")
      expect(page).to have_content("Please re-assess immunity enforcement response")

      # Fill in immunity response again
      within("#assess-immunity-detail-section") do
        choose "No"

        fill_in "Describe why the application is not immune from enforcement", with: "Application is not immune"
      end

      within("#permitted-development-right-section") do
        choose "Yes"

        fill_in "Describe how permitted development rights have been removed", with: "A reason"
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Immunity/permitted development rights response was successfully created")

      sign_in(reviewer)
      visit "/planning_applications/#{planning_application.reference}"
      click_link "Review and sign-off"

      click_button "Review evidence of immunity"

      within("#review-immunity-details") do
        choose "Agree"
        click_button "Save and mark as complete"
      end
      expect(page).to have_content("Review immunity details was successfully updated")

      click_button "Review assessment of immunity"

      within("#review-immunity-enforcements") do
        expect(page).to have_content("Assessor decision: No")
        expect(page).to have_content("Reason: Application is not immune")

        choose("Agree", match: :first)
        click_button "Save and mark as complete"
      end
      expect(page).to have_content("Review immunity details was successfully updated for enforcement")

      within("#review-permitted-development-rights") do
        click_button "Review permitted development rights"
        expect(page).to have_content("The permitted development rights have been removed for the following reason")
        expect(page).to have_content("A reason")

        choose "Agree"
        click_button "Save and mark as complete"
      end

      expect(page).to have_content("Permitted development rights response was successfully updated")

      expect(immunity_detail.current_evidence_review_immunity_detail.accepted?).to be(true)
      expect(immunity_detail.current_enforcement_review_immunity_detail.accepted?).to be(true)
    end
  end
end
