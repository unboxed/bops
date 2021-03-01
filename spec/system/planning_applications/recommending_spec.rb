# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, local_authority: @default_local_authority
  end

  before do
    sign_in assessor
    visit root_path
    click_link "In assessment"
    click_link planning_application.reference
  end

  context "with no previous recommendations" do
    it "can create a new recommendation, edit it, and submit it" do
      click_link "Assess proposal"
      choose "Yes"
      fill_in "Please provide supporting information to indicate which GDPO policy(s) have or have not been met.", with: "This is a public comment"
      fill_in "Please provide supporting information for your manager.", with: "This is a private assessor comment"
      click_button "Save"

      planning_application.reload
      expect(planning_application.recommendations.count).to eq(1)
      expect(planning_application.public_comment).to eq("This is a public comment")
      expect(planning_application.recommendations.first.assessor_comment).to eq("This is a private assessor comment")
      expect(planning_application.decision).to eq("granted")

      click_link "Assess proposal"
      expect(page).to have_checked_field("Yes")
      expect(page).to have_field("Please provide supporting information for your manager.", with: "This is a private assessor comment")
      choose "No"
      fill_in "Please provide supporting information to indicate which GDPO policy(s) have or have not been met.", with: "This is a new public comment"
      fill_in "Please provide supporting information for your manager.", with: "Edited private assessor comment"
      click_button "Save"
      planning_application.reload
      expect(planning_application.recommendations.count).to eq(1)
      expect(planning_application.recommendations.first.assessor_comment).to eq("Edited private assessor comment")
      expect(planning_application.decision).to eq("refused")
      expect(planning_application.public_comment).to eq("This is a new public comment")

      click_link "Submit recommendation"
      click_button "Submit to manager"

      # TODO: add a flash message here?
      planning_application.reload
      expect(planning_application.status).to eq("awaiting_determination")

      click_button "Key application dates"
      click_link "Activity log"

      expect(page).to have_text("Application rejected")
      expect(page).to have_text(assessor.name)
      expect(page).to have_text("Edited private assessor comment")
      expect(page).to have_text(Audit.all.last.created_at)
    end
  end

  context "with previous recommendations" do
    let!(:planning_application) do
      create :planning_application, :awaiting_correction, local_authority: @default_local_authority
    end

    let!(:recommendation) do
      create :recommendation, :reviewed, planning_application: planning_application,
                                         reviewer_comment: "I disagree", assessor_comment: "This looks good"
    end

    it "displays the previous recommendations" do
      click_link "Assess proposal"

      within ".recommendations" do
        expect(page).to have_content("I disagree")
        expect(page).to have_content("This looks good")
      end

      choose "Yes"
      fill_in "Please provide supporting information to indicate which GDPO policy(s) have or have not been met.", with: "This is so granted and GDPO everything"
      fill_in "Please provide supporting information for your manager.", with: "This is a private assessor comment"
      click_button "Save"

      planning_application.reload
      expect(planning_application.recommendations.count).to eq(2)
      expect(planning_application.public_comment).to eq("This is so granted and GDPO everything")
      expect(planning_application.recommendations.last.assessor_comment).to eq("This is a private assessor comment")
      expect(planning_application.decision).to eq("granted")

      click_link "Assess proposal"

      within ".recommendations" do
        expect(page).to have_content("I disagree")
        expect(page).to have_content("This looks good")
        expect(page).not_to have_content("This is a private assessor comment")
      end

      expect(page).to have_checked_field("Yes")
      expect(page).to have_field("assessor_comment", with: "This is a private assessor comment")

      click_button "Key application dates"
      click_link "Activity log"

      expect(page).to have_text("Application approved")
      expect(page).to have_text(assessor.name)
      expect(page).to have_text("This is a private assessor comment")
      expect(page).to have_text(Audit.all.last.created_at)
    end
  end

  it "errors if no public comment is provided when providing rejection recommendation" do
    click_link "Assess proposal"
    choose "No"
    fill_in "Please provide supporting information for your manager.", with: "This is a private assessor comment"
    fill_in "Please provide supporting information to indicate which GDPO policy(s) have or have not been met.", with: ""
    click_button "Save"

    expect(page).to have_content("Please fill in the GDPO policies text box.")

    expect(planning_application.status).to eq("in_assessment")
  end

  it "errors if no decision given" do
    click_link "Assess proposal"
    click_button "Save"

    expect(page).to have_content("Please select Yes or No")

    expect(planning_application.status).to eq("in_assessment")
  end
end
