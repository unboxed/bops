# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assigning a planning application", type: :system do
  let(:local_authority) { @default_local_authority }
  let!(:assessor1) { create :user, :assessor, local_authority: local_authority, name: "Assessor 1" }
  let!(:assessor2) { create :user, :assessor, local_authority: local_authority, name: "Assessor 2" }
  let!(:planning_application) { create :planning_application, local_authority: local_authority, user: assessor1 }

  let(:policy_consideration_1) do
    create :policy_consideration,
           policy_question: "The property is",
           applicant_answer: "a semi detached house"
  end

  let!(:policy_evaluation) do
    create :policy_evaluation,
           planning_application: planning_application,
           policy_considerations: [policy_consideration_1]
  end

  before do
    sign_in assessor1
    visit planning_application_path(planning_application)
  end

  it "is possible to assign to a user" do
    within ".assigned_to" do
      expect(page).to have_text("Assessor 1")
      click_link "Change"
    end
    choose "Assessor 2"
    click_button "Confirm"
    within ".assigned_to" do
      expect(page).to have_text("Assessor 2")
    end
  end

  it "is possible to assign to nobody" do
    within ".assigned_to" do
      expect(page).to have_text("Assessor 1")
      click_link "Change"
    end
    choose "Unassigned"
    click_button "Confirm"
    within ".assigned_to" do
      expect(page).to have_text("Unassigned")
    end
  end

  it "is not possible to submit an unassigned application" do
    click_link "Assess the proposal"

    choose "Yes"

    fill_in "private_comment", with: "This is a private comment"

    click_button "Save"

    within ".assigned_to" do
      expect(page).to have_text("Assessor 1")
      click_link "Change"
    end
    choose "Unassigned"
    click_button "Confirm"

    click_link "Submit the recommendation"

    expect(page).to have_text("Please assign this planning application before submitting for determination.")
    expect(page).not_to have_button("Submit to manager")
  end
end
