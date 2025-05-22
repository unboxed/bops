# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing assessment against policies and guidance", type: :system, js: true do
  let!(:local_authority) { create(:local_authority, :default, planning_policy_and_guidance: "http://example.com") }
  let!(:api_user) { create(:api_user, permissions: %w[validation_request:read], local_authority:) }
  let!(:assessor) { create(:user, :assessor, local_authority:, name: "Anne Assessor") }
  let!(:reviewer) { create(:user, :reviewer, local_authority:, name: "Ray Reviewer") }
  let(:consideration_set) { planning_application.consideration_set }
  let(:current_review) { consideration_set.current_review }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :awaiting_determination, :with_recommendation, local_authority:)
  end

  let(:reference) { planning_application.reference }

  before do
    create(:local_authority_policy_area, local_authority:, description: "Design")
    create(:local_authority_policy_reference, local_authority:, code: "PP100", description: "Wall materials")
    create(:local_authority_policy_reference, local_authority:, code: "PP101", description: "Roofing materials")
    create(:local_authority_policy_guidance, local_authority:, description: "Design Guidance")
  end

  context "when signed in as a reviewer" do
    before do
      travel_to Time.zone.local(2024, 7, 23, 11)

      sign_in(assessor)
      visit "/planning_applications/#{reference}/assessment/tasks"

      click_link "Assess against policies and guidance"
      expect(page).to have_selector("h1", text: "Assess against policies and guidance")

      within_fieldset("Add a new consideration") do
        with_retry do
          fill_in "Enter policy area", with: "Design"
          expect(page).to have_selector(:autoselect_option, ["#consideration-policy-area-field", "Design"])

          pick "Design", from: "#consideration-policy-area-field"
        end

        with_retry do
          fill_in "Enter policy references", with: "Wall"
          expect(page).to have_selector(:autoselect_option, ["#policyReferencesAutoComplete", "PP100 - Wall materials"])

          pick "PP100 - Wall materials", from: "#policyReferencesAutoComplete"
        end

        with_retry do
          fill_in "Enter policy references", with: "Roofing"
          expect(page).to have_selector(:autoselect_option, ["#policyReferencesAutoComplete", "PP101 - Roofing materials"])

          pick "PP101 - Roofing materials", from: "#policyReferencesAutoComplete"
        end

        with_retry do
          fill_in "Enter policy guidance", with: "Design"
          expect(page).to have_selector(:autoselect_option, ["#policyGuidanceAutoComplete", "Design Guidance"])

          pick "Design Guidance", from: "#policyGuidanceAutoComplete"
        end

        fill_in "Enter assessment", with: "Uses red brick with grey slates"
        fill_in "Enter conclusion", with: "Complies with design guidance policies"
      end

      click_button "Add consideration"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/considerations/edit")
      expect(page).to have_content("Consideration was successfully added")

      within "main ol" do
        within "li:nth-of-type(1)" do
          expect(page).to have_selector("h2", text: "Design")
        end
      end

      click_button "Save and mark as complete"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")
      expect(page).to have_content("Assessment against local policies was successfully saved")

      sign_in(reviewer)
      visit "/planning_applications/#{reference}/review/tasks"
    end

    it "shows validation errors" do
      click_button "Review assessment against policies and guidance"
      within("#considerations_footer") do
        click_button("Save and mark as complete")
      end
      expect(page).to have_selector("[role=alert] li", text: "Select an option")

      within("#considerations_section") do
        within(".bops-task-accordion__section-header") do
          expect(find("button")[:"aria-expanded"]).to eq("true")
        end
        within("#considerations_footer") do
          expect(page).to have_selector("a", text: "Select an option")
        end

        within("#considerations_footer") do
          choose "Return with comments"
          click_button("Save and mark as complete")
        end
      end

      expect(page).to have_selector("[role=alert] li", text: "Explain to the case officer why")

      within("#considerations_section") do
        within(".bops-task-accordion__section-header") do
          expect(find("button")[:"aria-expanded"]).to eq("true")
        end
        within("#considerations_footer") do
          expect(page).to have_selector("p.govuk-error-message", text: "Explain to the case officer why")
        end
      end
    end

    it "I can accept the planning officer's decision" do
      click_button "Review assessment against policies and guidance"
      within("#considerations_section") do
        expect(find(".govuk-tag")).to have_content("Not started")

        within("#considerations_block") do
          expect(page).to have_link("Check your local policies and guidance (in a new tab)")

          consideration = Consideration.last
          within("#consideration_#{consideration.id}") do
            expect(page).to have_selector("span", text: "Consideration 1")
            expect(page).to have_selector("h2", text: "Design")
            expect(page).to have_link(
              "Edit to accept",
              href: "/planning_applications/#{reference}/review/considerations/items/#{consideration.id}/edit"
            )
            expect(page).to have_selector("p", text: "Uses red brick with grey slates", visible: false)
            expect(page).to have_selector("p", text: "Complies with design guidance policies", visible: false)

            click_button("Show more")
            expect(page).to have_selector("p", text: "Uses red brick with grey slates", visible: true)
            expect(page).to have_selector("p", text: "Complies with design guidance policies", visible: true)

            click_button("Show less")
            expect(page).to have_selector("p", text: "Uses red brick with grey slates", visible: false)
            expect(page).to have_selector("p", text: "Complies with design guidance policies", visible: false)
          end

          expect(page).to have_link(
            "Edit list position",
            href: "/planning_applications/#{reference}/review/considerations/edit"
          )
        end

        choose "Agree"

        expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")
        click_button "Save and mark as complete"
      end
      expect(page).to have_content("Review of assessment against policy and guidance updated successfully")
      click_button "Review assessment against policies and guidance"
      within("#considerations_section") do
        expect(find(".govuk-tag")).to have_content("Completed")
      end

      expect(current_review.reload).to have_attributes(action: "accepted", review_status: "review_complete")

      within("#considerations_block") do
        click_link("Edit list position")
      end

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")
      expect(page).to have_content("Assessment accepted by Ray Reviewer, 23 July 2024")
    end

    it "I can edit and accept the planning officer's decision" do
      click_button "Review assessment against policies and guidance"

      within("#considerations_block") do
        click_link "Edit to accept"
      end

      expect(page).to have_selector("h1", text: "Edit consideration")

      fill_in "Enter assessment", with: "Uses yellow brick with grey slates"

      click_button "Save consideration"
      expect(page).to have_content("Consideration was successfully saved")

      click_button "Review assessment against policies and guidance"
      within("#considerations_block") do
        click_button("Show more")
        expect(page).to have_selector("p", text: "Uses yellow brick with grey slates")
      end

      within("#considerations_footer") do
        choose "Agree"

        expect(current_review).to have_attributes(action: nil, review_status: "review_not_started")

        click_button "Save and mark as complete"
      end

      expect(page).to have_content("Review of assessment against policy and guidance updated successfully")
      within("#considerations_section") do
        expect(find(".govuk-tag")).to have_content("Completed")
      end

      expect(current_review.reload).to have_attributes(action: "accepted", review_status: "review_complete")

      click_button "Review assessment against policies and guidance"
      within("#considerations_block") do
        click_link("Edit list position")
      end

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")
      expect(page).to have_content("Assessment accepted by Ray Reviewer, 23 July 2024")
    end

    it "I can return to the planning officer with a comment" do
      click_button "Review assessment against policies and guidance"
      expect(page).to have_selector(:open_review_task, text: "Review assessment against policies and guidance")

      within("#considerations_footer") do
        choose "Return with comments"
        fill_in "Add a comment", with: "Please provide more details about the design of the property"

        expect(current_review).to have_attributes(action: nil, review_status: "review_not_started", comment: nil)

        click_button "Save and mark as complete"
      end

      expect(page).to have_current_path("/planning_applications/#{reference}/review/tasks")
      expect(page).to have_content("Review of assessment against policy and guidance updated successfully")

      within("#considerations_section") do
        expect(find(".govuk-tag")).to have_content("Awaiting changes")
      end

      expect(current_review.reload).to have_attributes(action: "rejected", review_status: "review_complete", comment: "Please provide more details about the design of the property")

      click_button "Review assessment against policies and guidance"
      expect(page).to have_selector(:open_review_task, text: "Review assessment against policies and guidance")

      within("#considerations_block") do
        click_link("Edit list position")
      end

      expect(page).to have_selector("h1", text: "Review assessment against policies and guidance")
      expect(page).to have_content("Assessment rejected by Ray Reviewer, 23 July 2024")

      travel_to Time.zone.local(2024, 7, 23, 12)
      sign_in(assessor)

      visit "/planning_applications/#{reference}/assessment/tasks"
      expect(page).to have_list_item_for("Assess against policies and guidance", with: "To be reviewed")

      click_link "Assess against policies and guidance"

      expect(page).to have_selector("h1", text: "Assess against policies and guidance")
      expect(page).to have_content("Please provide more details about the design of the property")
      expect(page).to have_content("Sent on 23 July 2024 11:00 by Ray Reviewer")

      click_link "Edit"
      expect(page).to have_selector("h1", text: "Edit consideration")

      fill_in "Enter assessment", with: "Uses yellow brick with grey slates"

      click_button "Save consideration"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/considerations/edit")
      expect(page).to have_content("Consideration was successfully saved")

      click_button "Save and mark as complete"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/tasks")
      expect(page).to have_content("Assessment against local policies was successfully saved")
      expect(page).to have_list_item_for("Assess against policies and guidance", with: "Updated")

      travel_to Time.zone.local(2024, 7, 23, 13)
      sign_in(reviewer)

      visit "/planning_applications/#{reference}/review/tasks"

      click_button "Review assessment against policies and guidance"
      expect(page).to have_selector(:open_review_task, text: "Review assessment against policies and guidance")

      within("#considerations_section") do
        expect(find(".govuk-tag")).to have_content("Updated")
      end

      within("#considerations_footer") do
        choose "Agree"
        click_button "Save and mark as complete"
      end

      expect(page).to have_current_path("/planning_applications/#{reference}/review/tasks")
      expect(page).to have_content("Review of assessment against policy and guidance updated successfully")

      within("#considerations_section") do
        expect(find(".govuk-tag")).to have_content("Completed")
      end

      click_button "Review assessment against policies and guidance"
      expect(page).to have_selector(:open_review_task, text: "Review assessment against policies and guidance")

      within("#considerations_block") do
        click_link("Edit list position")
      end

      expect(page).to have_content("Assessment accepted by Ray Reviewer, 23 July 2024")
    end
  end
end
