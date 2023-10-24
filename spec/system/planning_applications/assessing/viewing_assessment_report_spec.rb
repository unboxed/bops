# frozen_string_literal: true

require "rails_helper"

RSpec.describe "viewing assessment report" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let(:local_authority) { create(:local_authority, :default) }

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
      :in_assessment,
      :with_constraints,
      local_authority:,
      decision: :granted,
      old_constraints: ["conservation_area"],
      api_user:
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

  let!(:consultation) do
    create(:consultation, planning_application:)
  end

  before do
    create(
      :recommendation,
      planning_application:
    )

    create(
      :assessment_detail,
      :past_applications,
      planning_application:,
      entry: "22-00999-LDCP",
      additional_information: "This is the past application history summary."
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
      consultation:,
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
      :policy_class,
      :complies,
      planning_application:,
      part: 1,
      section: "A",
      name: "Window boxes"
    )
  end

  it "lets the user view and download the report" do
    sign_in(assessor)
    visit planning_application_assessment_tasks_path(planning_application)
    click_link("Review and submit recommendation")
    click_button("Assessment report details")

    expect(page).to have_content("Conservation area")
    expect(page).to have_content("22-00999-LDCP")
    expect(page).to have_content("This is the past application history summary.")
    expect(page).to have_content("This is the summary of work.")
    expect(page).to have_content("This is the location description.")
    expect(page).to have_content("Alice Smith (external)")
    expect(page).to have_content("This is the consultation summary.")
    expect(page).to have_content("Part 1, Class A - Window boxes")
    expect(page).to have_content("Complies")
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
