# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Summary of advice task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :pre_application, local_authority:) }
  let(:user) { create(:user, local_authority:) }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
  end

  it "Can complete and submit the summary of advice" do
    within ".bops-sidebar" do
      click_link "Summary of advice"
    end
    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/summary-of-advice")
    expect(page).to have_content("Summary of advice")

    choose "Likely to be supported (recommended based on considerations)"
    fill_in "Enter summary of planning considerations and advice. This should summarise any changes the applicant needs to make before they make an application.", with: "It is my recommendation that if a formal application were to be submitted this would be granted."
    click_button "Save"

    expect(page).to have_content("Summary of advice successfully updated")
    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/summary-of-advice")

    expect(page).not_to have_content("#outcome-form")
    expect(page).to have_content("Your proposal is likely to be supported based on the information you have provided.")

    click_on "Edit summary of advice"

    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/summary-of-advice/edit")

    within "#outcome-form" do
      choose "Likely to be supported with changes"
      click_button "Save"
    end

    expect(page).to have_content("Summary of advice successfully updated")
    expect(page).to have_current_path("/preapps/#{planning_application.reference}/check-and-assess/assessment-summaries/summary-of-advice")
  end
end
