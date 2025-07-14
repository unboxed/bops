# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recommending and submitting a pre-application report" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:, name: "Jane Smith") }
  let(:reviewer) { create(:user, :reviewer, local_authority:, name: "Alan Jones") }

  let(:case_record) { build(:case_record, user: assessor, local_authority:) }
  let(:planning_application) do
    create(
      :planning_application,
      :pre_application,
      :in_assessment,
      :with_preapp_assessment,
      local_authority:,
      case_record:
    )
  end

  let(:reference) { planning_application.reference }

  it "can be recommended and reviewed" do
    sign_in(assessor)

    visit "/reports/planning_applications/#{reference}"
    expect(page).to have_selector("h1", text: "Pre-application report")

    click_button "Confirm and submit recommendation"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report submitted for review")

    click_link "Review and submit pre-application"
    expect(page).to have_selector("h1", text: "Pre-application report")

    click_button "Withdraw recommendation"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report withdrawn")

    click_link "Review and submit pre-application"
    expect(page).to have_selector("h1", text: "Pre-application report")

    click_button "Confirm and submit recommendation"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report submitted for review")

    sign_out(assessor)
    sign_in(reviewer)

    visit "/reports/planning_applications/#{reference}"
    expect(page).to have_selector("h1", text: "Pre-application report")

    expect(page).to have_content("Submitted recommendation")
    expect(page).to have_content("by Jane Smith")

    within_fieldset "Do you agree with the advice?" do
      choose "No (return the case for assessment)"
      fill_in "Reviewer comment", with: "Not good enough"
    end

    click_button "Confirm and submit pre-application report"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report has been sent back to the case officer for amendments")

    expect(BopsReports::SendReportEmailJob).not_to have_been_enqueued

    sign_out(reviewer)
    sign_in(assessor)

    visit "/reports/planning_applications/#{reference}"
    expect(page).to have_selector("h1", text: "Pre-application report")

    fill_in "Assessor comment", with: "It is now"

    click_button "Confirm and submit recommendation"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report submitted for review")

    sign_out(assessor)
    sign_in(reviewer)

    visit "/reports/planning_applications/#{reference}"
    expect(page).to have_selector("h1", text: "Pre-application report")
    expect(page).to have_content("It is now")

    click_button "Confirm and submit pre-application report"
    expect(page).to have_selector("[role=alert] p", text: "Review submission failed – check the form for errors")
    expect(page).to have_content("Choose one of the options 'Yes' or 'No'")

    within_fieldset "Do you agree with the advice?" do
      choose "Yes"
    end

    click_button "Confirm and submit pre-application report"

    expect(BopsReports::SendReportEmailJob).to have_been_enqueued.with(
      planning_application,
      reviewer
    ).once

    expect(page).to have_selector("[role=alert] p", text: "Pre-application report has been sent to the applicant")
  end

  it "requires an assigned case officer before you can submit the recommendation" do
    planning_application.case_record.update(user: nil)

    sign_in(assessor)

    visit "/reports/planning_applications/#{reference}"

    click_button "Confirm and submit recommendation"
    expect(page).to have_selector("[role=alert] p", text: "Pre-application report must be assigned to a case officer before it can be submitted for review")
  end

  context "when a reviewer skips assessment and publishes directly" do
    before do
      sign_in(reviewer)
      visit "/reports/planning_applications/#{reference}"
    end

    it "allows them to send the report to the applicant" do
      click_button "Confirm and submit pre-application report"

      expect(BopsReports::SendReportEmailJob).to have_been_enqueued.with(
        planning_application,
        reviewer
      ).once

      expect(page).to have_selector("[role=alert] p",
        text: "Pre-application report has been sent to the applicant")
    end
  end
end
