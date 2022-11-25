# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Reviewing Policy Class", type: :system do
  let(:default_local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create :user, :reviewer, local_authority: default_local_authority }
  let!(:assessor) { create :user, name: "Chuck The Assessor", local_authority: default_local_authority }
  let!(:planning_application) do
    create(
      :planning_application,
      :awaiting_determination,
      :with_recommendation,
      local_authority: default_local_authority
    )
  end

  context "with a reviewer" do
    before do
      sign_in reviewer
    end

    it "can make the policy class reviewed" do
      policy_class = create(:policy_class, section: "A", planning_application: planning_application)
      create(:policy, policy_class: policy_class)
      visit(planning_application_review_tasks_path(planning_application))

      expect(page).to have_selector("h1", text: "Review and sign-off")
      click_on "Review assessment of Part 1, Class A"

      choose "Accept"

      click_on "Save and mark as complete"

      expect(page).to have_text "Successfully updated policy class"
      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Complete")

      click_on "Review assessment of Part 1, Class A"

      expect(page).to have_text "Accept"

      click_on "Edit review of Part 1, Class A"

      click_on "Save and come back later"

      expect(page).to have_text "Successfully updated policy class"
      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Not checked yet")
    end

    it "can return legislation to officer with comment" do
      policy_class = create(:policy_class, section: "A", planning_application: planning_application)
      create(:policy, policy_class: policy_class)
      visit(planning_application_review_tasks_path(planning_application))

      expect(page).to have_selector("h1", text: "Review and sign-off")
      click_on "Review assessment of Part 1, Class A"

      choose "Return to officer with comment"

      fill_in "Explain to the assessor why this needs reviewing", with: "Officer comment"

      click_on "Save and mark as complete"

      expect(page).to have_text "Successfully updated policy class"
      expect(list_item("Review assessment of Part 1, Class A")).to have_content("Complete")

      click_on "Review assessment of Part 1, Class A"

      expect(page).to have_text "Return to officer with comment"

      click_on "Back"

      visit(planning_application_assessment_tasks_path(planning_application))

      expect(list_item("Part 1, Class A")).to have_content("To be reviewed")
    end

    it "displays policy_class with comments" do
      travel_to Time.zone.local(2020, 10, 15, 12, 0, 1) do
        Current.user = assessor
        policy_class = create(:policy_class, section: "A", name: "Roof", planning_application: planning_application)
        policy = create(:policy, policy_class: policy_class, description: "Policy description")
        create(:comment, commentable: policy, text: "policy comment", user: assessor)
        visit(planning_application_review_tasks_path(planning_application))
        click_on "Review assessment of Part 1, Class A"

        expect(page).to have_text("Part 1, Class A - Roof")
        expect(page).to have_selector("p", text: "Policy description")
        expect(page).to have_text("15 Oct 2020 by Chuck The Assessor")
        expect(page).to have_text("policy comment")
      end
    end

    it "can display errors" do
      policy_class = create(:policy_class, section: "A", planning_application: planning_application)
      create(:policy, policy_class: policy_class)
      visit(planning_application_review_tasks_path(planning_application))

      expect(page).to have_selector("h1", text: "Review and sign-off")
      click_on "Review assessment of Part 1, Class A"

      click_on "Save and mark as complete"

      expect(page).to have_text("can't be blank")
    end
  end
end
