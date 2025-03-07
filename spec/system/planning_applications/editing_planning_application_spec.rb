# frozen_string_literal: true

require "rails_helper"

RSpec.describe "editing planning application" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      :ldc_proposed,
      local_authority:
    )
  end

  before do
    travel_to(DateTime.new(2023, 1, 1))
    sign_in(assessor)
    create(:application_type, :prior_approval, local_authority:)
    create(:application_type, :ldc_existing, local_authority:)
    visit "/planning_applications/#{planning_application.reference}"
  end

  it "returns the user to the previous page after updating" do
    click_link("Check and assess")
    find("span", text: "Application information")
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

    select("Lawful Development Certificate - Existing use")

    within(find(:fieldset, text: "Agent information")) do
      fill_in("Email address", with: "alice@example.com")
    end

    within(find(:fieldset, text: "Applicant information")) do
      fill_in("Email address", with: "belle@example.com")
    end

    click_button("Save")
    planning_application.reload

    expect(page).to have_content(
      "Planning application was successfully updated."
    )
    within("#planning-application-details") do
      expect(page).to have_content(planning_application.description)
    end

    expect(page).to have_current_path(
      "/planning_applications/#{planning_application.reference}/assessment/tasks"
    )

    click_link("Check application details")
    find("span", text: "Application information")
    click_link("Edit details")

    expect(page).to have_content("Application number: 23-00100-LDCE (Previously: 23-00100-LDCP)")
    expect(page).to have_select("planning-application-application-type-id-field", selected: "Lawful Development Certificate - Existing use")
    fill_in("Address 1", with: "125 High Street")
    click_button("Save")
    planning_application.reload

    expect(page).to have_content(
      "Planning application was successfully updated."
    )

    expect(page).to have_current_path(
      "/planning_applications/#{planning_application.reference}/assessment/consistency_checklist/new"
    )

    # Check audit
    visit "/planning_applications/#{planning_application.reference}/audits"
    within("#audit_#{Audit.find_by(activity_information: "Application type").id}") do
      expect(page).to have_content("Application type updated")
      expect(page).to have_content(
        "Application type changed from: Lawfulness certificate / Changed to: Lawfulness certificate, Reference changed from 23-00100-LDCP to 23-00100-LDCE"
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
      find("span", text: "Application information").click
      click_link("Edit details")

      fill_in("Postcode", with: "123ABC")

      click_button("Save")

      expect(page).to have_content("Please save and mark as complete the draft recommendation before updating application fields.")
      expect(page).to have_link("draft recommendation", href: new_planning_application_assessment_recommendation_path(planning_application))
    end
  end
end
