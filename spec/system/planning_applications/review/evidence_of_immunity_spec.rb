# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing evidence of immunity", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }

  let(:reviewer) do
    create(
      :user,
      :reviewer,
      local_authority: default_local_authority,
      name: "Charlize The Reviever"
    )
  end

  let(:assessor) { create(:user, local_authority: default_local_authority) }

  let(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      :with_recommendation,
      :with_immunity,
      local_authority: default_local_authority,
      decision: :granted
    )
  end

  context "when there's not an evidence of immunity" do
    before do
      sign_in reviewer
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    it "I cannot view the link of Review evidence of immunity page" do
      expect(page).not_to have_link("Review evidence of immunity")
    end
  end

  context "when there's an evidence of immunity" do
    before do
      create(:review, :evidence, owner: planning_application.immunity_detail, assessor:)
      create(:evidence_group, :with_document, tag: "utilityBill", missing_evidence: true, missing_evidence_entry: "gaps everywhere", immunity_detail: planning_application.immunity_detail)
      create(:evidence_group, :with_document, tag: "buildingControlCertificate", end_date: nil, immunity_detail: planning_application.immunity_detail)

      sign_in reviewer
      visit "/planning_applications/#{planning_application.reference}/review/tasks"
    end

    context "when planning application is awaiting determination", :capybara do
      it "I can save and mark as complete when adding my review to accept the review evidence of immunity response" do
        within("#review-immunity-details") do
          expect(page).to have_content("Review evidence of immunity")
          expect(page).to have_content("Not started")
        end

        click_button "Review evidence of immunity"

        within("#review-immunity-details") do
          expect(page).to have_content("Were the works carried out more than 4 years ago? Yes")
          expect(page).to have_content("Have the works been completed? Yes")
          expect(page).to have_content("When were the works completed? 01/02/2015")
          expect(page).to have_content("Has anyone ever attempted to conceal the changes? No")
          expect(page).to have_content("Has enforcement action been taken about these changes? No")

          choose "Agree"
          click_button "Save and mark as complete"
        end

        expect(page).to have_content("Review immunity details was successfully updated")

        within("#review-immunity-details") do
          expect(page).to have_content("Review evidence of immunity")
          expect(page).to have_content("Completed")
        end
      end

      it "when I return it with comments, they can see my comments" do
        within("#review-immunity-details") do
          expect(page).to have_content("Review evidence of immunity")
          expect(page).to have_content("Not started")
        end

        click_button "Review evidence of immunity"

        within("#review-immunity-details") do
          expect(page).to have_content("Were the works carried out more than 4 years ago? Yes")
          expect(page).to have_content("Have the works been completed? Yes")
          expect(page).to have_content("When were the works completed? 01/02/2015")
          expect(page).to have_content("Has anyone ever attempted to conceal the changes? No")
          expect(page).to have_content("Has enforcement action been taken about these changes? No")

          choose "Return with comments"

          fill_in "Add a comment", with: "Please re-assess"

          click_button "Save and mark as complete"
        end

        click_link "Application"
        click_link "Check and assess"

        expect(page).to have_list_item_for(
          "Evidence of immunity",
          with: "To be reviewed"
        )

        click_link "Evidence of immunity"

        expect(page).to have_content("Please re-assess")
      end
    end
  end
end
