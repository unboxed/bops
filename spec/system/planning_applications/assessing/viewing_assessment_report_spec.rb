# frozen_string_literal: true

require "rails_helper"

RSpec.describe "viewing assessment report", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority:
    )
  end

  let!(:planning_application) do
    create(
      :planning_application,
      :prior_approval,
      :in_assessment,
      :with_constraints,
      local_authority:,
      decision: :granted,
      api_user:,
      user: assessor
    )
  end

  let!(:document) do
    create(
      :document,
      planning_application:,
      referenced_in_decision_notice: true,
      numbers: "REF1"
    )
  end

  before do
    create(
      :recommendation,
      planning_application:
    )

    create(
      :assessment_detail,
      :summary_of_work,
      planning_application:,
      entry: "This is the summary of work."
    )

    create(
      :assessment_detail,
      :site_description,
      planning_application:,
      entry: "This is the location description."
    )

    create(
      :assessment_detail,
      :additional_evidence,
      planning_application:,
      entry: "This is the additional evidence."
    )

    create(
      :consultee,
      consultation: planning_application.consultation,
      name: "Alice Smith",
      origin: :external
    )

    create(
      :assessment_detail,
      :consultation_summary,
      planning_application:,
      entry: "This is the consultation summary."
    )

    create(
      :site_history,
      planning_application:,
      application_number: "22-00999-LDCP",
      description: "This is the past application history summary."
    )
  end

  it "lets the user view and download the report" do
    sign_in(assessor)
    visit "/planning_applications/#{planning_application.reference}/assessment/tasks"
    click_link("Review and submit recommendation")
    click_button("Assessment report details")

    within("#application-details-section") do
      expect(page).to have_content(planning_application.applicant_name)
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content(planning_application.application_type.description)
      expect(page).to have_content(planning_application.determination_date.to_fs)
      expect(page).to have_content(planning_application.user.name)
    end

    expect(page).to have_content("Conservation area")
    expect(page).to have_content("22-00999-LDCP")
    expect(page).to have_content("This is the past application history summary.")
    expect(page).to have_content("This is the summary of work.")
    expect(page).to have_content("This is the location description.")
    expect(page).to have_content("Alice Smith (external)")
    expect(page).to have_content("This is the consultation summary.")
    expect(page).to have_content(document.name)

    expect(page).not_to have_content("This is the additional evidence.")

    expect(page).to have_link(
      "Download assessment report as PDF",
      href: planning_application_assessment_report_download_path(
        planning_application,
        format: "pdf"
      )
    )
  end
end
