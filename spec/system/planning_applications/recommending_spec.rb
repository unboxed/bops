# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, local_authority: @default_local_authority
  end

  # TODO: have multiple previous recommendations, and check they are shown on page

  before do
    sign_in assessor
    visit root_path
    click_link "In assessment"
    click_link planning_application.reference
  end

  context "with no previous recommendations" do
    it "can create a new recommendation, edit it, and submit it" do
      click_link "Assess Proposal"
      choose "Yes"
      fill_in "assessor_comment", with: "This is a private assessor comment"
      click_button "Save"

      planning_application.reload
      expect(planning_application.recommendations.count).to eq(1)
      expect(planning_application.recommendations.first.assessor_comment).to eq("This is a private assessor comment")
      expect(planning_application.decision).to eq("granted")

      click_link "Assess Proposal"
      expect(page).to have_checked_field("Yes")
      expect(page).to have_field("assessor_comment", with: "This is a private assessor comment")
      choose "No"
      fill_in "public_comment", with: "This is a new public comment"
      fill_in "assessor_comment", with: "Edited private assessor comment"
      click_button "Save"
      planning_application.reload
      expect(planning_application.recommendations.count).to eq(1)
      expect(planning_application.recommendations.first.assessor_comment).to eq("Edited private assessor comment")
      expect(planning_application.decision).to eq("refused")
      expect(planning_application.public_comment).to eq("This is a new public comment")

      click_link "Submit Recommendation"
      click_button "Submit to manager"

      # TODO: add a flash message here?
      planning_application.reload
      expect(planning_application.status).to eq("awaiting_determination")
    end
  end

  it "errors if no public comment is provided when providing rejection recommendation" do
    click_link "Assess Proposal"
    choose "No"
    fill_in "assessor_comment", with: "This is a private assessor comment"
    fill_in "public_comment", with: ""
    click_button "Save"

    expect(page).to have_content("Please fill in the GDPO policies text box.")

    expect(planning_application.status).to eq("in_assessment")
  end

  it "errors if no decision given" do
    pending
    click_link "Assess Proposal"
    click_button "Save"

    expect(page).to have_content("Please select Yes or No")

    expect(planning_application.status).to eq("in_assessment")
  end
end
