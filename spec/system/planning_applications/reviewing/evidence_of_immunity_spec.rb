# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewing evidence of immunity" do
  let(:default_local_authority) { create(:local_authority, :default) }

  let(:reviewer) do
    create(
      :user,
      :reviewer,
      local_authority: default_local_authority,
      name: "Charlize The Reviever"
    )
  end

  let(:assessor) { create(:user, name: "Chuck The Assessor", local_authority: default_local_authority) }

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

  let!(:review_immunity_detail) { create(:review_immunity_detail, immunity_detail: planning_application.immunity_detail, assessor:) } # rubocop:disable RSpec/LetSetup

  before do
    sign_in reviewer
    visit(planning_application_review_tasks_path(planning_application))
  end

  context "when planning application is awaiting determination" do
    it "I can view the information on the review evidence of immunity page" do
      expect(page).to have_list_item_for(
        "Review evidence of immunity",
        with: "Not started"
      )

      click_link "Review evidence of immunity"

      within(".govuk-breadcrumbs__list") do
        expect(page).to have_content("Review")
        expect(page).to have_content("Evidence of immunity")
      end

      expect(page).to have_current_path(
        edit_planning_application_review_immunity_detail_path(planning_application, ReviewImmunityDetail.last)
      )

      expect(page).to have_content("Review evidence of immunity")
      expect(page).to have_content("Application number: #{planning_application.reference}")
      expect(page).to have_content(planning_application.full_address)

      expect(page).to have_content("Were the works carried out more than 4 years ago? Yes")
      expect(page).to have_content("Have the works been completed? Yes")
      expect(page).to have_content("When were the works completed? 01/02/2015")
      expect(page).to have_content("Has anyone ever attempted to conceal the changes? No")
      expect(page).to have_content("Has enforcement action been taken about these changes? No")
    end

    it "I can save and come back later when adding my review or editing the evidence of immunity" do
      click_link "Review evidence of immunity"

      choose "Accept"

      click_button "Save and come back later"
      expect(page).to have_content("Review immunity details was successfully updated")

      expect(page).to have_list_item_for(
        "Review evidence of immunity",
        with: "In progress"
      )

      click_link "Review evidence of immunity"

      expect(page).to have_checked_field("Accept")

      choose "Return to officer with comment"

      fill_in "Explain to the assessor why this needs reviewing", with: "Please re-assess"

      click_button "Save and come back later"
      expect(page).to have_content("Review immunity details was successfully updated")

      expect(page).to have_list_item_for(
        "Review evidence of immunity",
        with: "In progress"
      )

      click_link "Review evidence of immunity"

      expect(page).to have_checked_field("Return to officer with comment")

      expect(page).to have_content("Please re-assess")
    end

    it "I can save and mark as complete when adding my review to accept the review evidence of immunity response" do
      click_link "Review evidence of immunity"

      choose "Accept"

      click_button "Save and mark as complete"

      expect(page).to have_list_item_for(
        "Review evidence of immunity",
        with: "Completed"
      )

      click_link "Review evidence of immunity"

      expect(page).not_to have_content("Save and mark as complete")
    end

    it "when I return it to officer with comments, they can see my comments" do
      click_link "Review evidence of immunity"

      choose "Return to officer with comment"

      fill_in "Explain to the assessor why this needs reviewing", with: "Please re-assess"

      click_button "Save and mark as complete"

      click_link "Application"
      click_link "Check and assess"

      expect(page).to have_list_item_for(
        "Evidence of immunity",
        with: "To be reviewed"
      )

      click_link "Evidence of immunity"
      find("span", text: "See immunity detail checks").click

      expect(page).to have_content("Please re-assess")
    end
  end
end
