# frozen_string_literal: true

require "rails_helper"

RSpec.describe "editing planning application" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      local_authority:
    )
  end

  before do
    travel_to(DateTime.new(2023, 1, 1))
    sign_in(assessor)
    create(:application_type, :prior_approval)
    visit(planning_application_path(planning_application))
  end

  it "returns the user to the previous page after updating" do
    click_link("Check and assess")
    click_button("Application information")
    click_link("Edit details")

    expect(page).to have_content("Application number: 23-00100-LDC")

    within(find(:fieldset, text: "Agent information")) do
      fill_in("Email address", with: "")
    end

    within(find(:fieldset, text: "Applicant information")) do
      fill_in("Email address", with: "")
    end

    click_button("Save")

    expect(page).to have_content("An applicant or agent email is required.")

    select("Prior approval")

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
    within("#planning-application-details") do
      expect(page).to have_content("Prior approval")
    end

    expect(page).to have_current_path(
      planning_application_assessment_tasks_path(planning_application)
    )

    click_link("Check description, documents and proposal details")
    click_button("Application information")
    click_link("Edit details")

    expect(page).to have_content("Application number: 23-00101-PA")
    expect(page).to have_select("planning-application-application-type-id-field", selected: "Prior approval")
    fill_in("Address 1", with: "125 High Street")
    click_button("Save")

    expect(page).to have_content(
      "Planning application was successfully updated."
    )

    expect(page).to have_current_path(
      new_planning_application_consistency_checklist_path(planning_application)
    )

    # Check audit
    visit planning_application_audits_path(planning_application)
    within("#audit_#{Audit.find_by(activity_information: "Application type").id}") do
      expect(page).to have_content("Application type updated")
      expect(page).to have_content(
        "Application type changed from: Lawfulness certificate / Changed to: Prior approval, Reference changed from 23-00100-LDCP to 23-00101-PA"
      )
      expect(page).to have_content(assessor.name)
      expect(page).to have_content(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    end
  end

  context "when planning application status is assessment in progress" do
    let(:planning_application) do
      create(
        :planning_application,
        :assessment_in_progress,
        local_authority:
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
