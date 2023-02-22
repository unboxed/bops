# frozen_string_literal: true

require "rails_helper"

RSpec.describe "editing planning application" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority: local_authority) }

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      local_authority: local_authority
    )
  end

  before do
    sign_in(assessor)
    visit(planning_application_path(planning_application))
  end

  it "returns the user to the previous page after updating" do
    click_link("Check and assess")
    click_button("Application information")
    click_link("Edit details")

    within(find(:fieldset, text: "Agent information")) do
      fill_in("Email address", with: "")
    end

    within(find(:fieldset, text: "Applicant information")) do
      fill_in("Email address", with: "")
    end

    click_button("Save")

    expect(page).to have_content("An applicant or agent email is required.")

    within(find(:fieldset, text: "Agent information")) do
      fill_in("Email address", with: "alice@example.com")
    end

    within(find(:fieldset, text: "Applicant information")) do
      fill_in("Email address", with: "belle@example.com")
    end

    click_button("Save")

    expect(page).to have_content(
      "Planning application was successfully updated."
    )

    expect(page).to have_current_path(
      planning_application_assessment_tasks_path(planning_application)
    )

    click_link("Check description, documents and proposal details")
    click_button("Application information")
    click_link("Edit details")
    fill_in("Address 1", with: "125 High Street")
    click_button("Save")

    expect(page).to have_content(
      "Planning application was successfully updated."
    )

    expect(page).to have_current_path(
      new_planning_application_consistency_checklist_path(planning_application)
    )
  end

  context "when planning application status is assessment in progress" do
    let(:planning_application) do
      create(
        :planning_application,
        :assessment_in_progress,
        local_authority: local_authority
      )
    end

    it "prompts the user to complete their draft assessment before updating" do
      click_link("Check and assess")
      click_button("Application information")
      click_link("Edit details")

      fill_in("Postcode", with: "123ABC")

      click_button("Save")

      expect(page).to have_content("Please save and mark as complete the draft recommendation before updating application fields.")
      expect(page).to have_link("draft recommendation", href: new_planning_application_recommendation_path(planning_application))
    end
  end
end
