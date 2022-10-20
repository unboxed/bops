# frozen_string_literal: true

require "rails_helper"

RSpec.describe "viewing assessment report", type: :system do
  let(:local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority: local_authority
    )
  end

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      local_authority: local_authority,
      decision: :granted,
      constraints: ["conservation_area"]
    )
  end

  let!(:document) do
    create(
      :document,
      planning_application: planning_application,
      referenced_in_decision_notice: true,
      numbers: "REF1"
    )
  end

  before do
    create(
      :recommendation,
      planning_application: planning_application
    )

    create(
      :assessment_detail,
      :past_applications,
      planning_application: planning_application,
      entry: "22-00999-LDCP",
      additional_information: "This is the past application history summary."
    )

    create(
      :assessment_detail,
      :summary_of_work,
      planning_application: planning_application,
      entry: "This is the summary of work."
    )

    create(
      :assessment_detail,
      :site_description,
      planning_application: planning_application,
      entry: "This is the location description."
    )

    create(
      :consultee,
      planning_application: planning_application,
      name: "Alice Smith",
      origin: :external
    )

    create(
      :assessment_detail,
      :consultation_summary,
      planning_application: planning_application,
      entry: "This is the consulation summary."
    )

    create(
      :policy_class,
      :complies,
      planning_application: planning_application,
      part: 1,
      section: "A",
      name: "Window boxes"
    )
  end

  it "lets the user view and download the report" do
    sign_in(assessor)
    visit(planning_application_path(planning_application))
    click_link("Submit recommendation")
    click_button("Assessment report")

    expect(page).to have_content("Conservation area")
    expect(page).to have_content("22-00999-LDCP")
    expect(page).to have_content("This is the past application history summary.")
    expect(page).to have_content("This is the summary of work.")
    expect(page).to have_content("This is the location description.")
    expect(page).to have_content("Alice Smith (external)")
    expect(page).to have_content("This is the consulation summary.")
    expect(page).to have_content("Part 1, Class A - Window boxes")
    expect(page).to have_content("Complies")
    expect(page).to have_content(document.name)

    expect(page).to have_link(
      "Download assessment report as PDF",
      href: planning_application_assessment_report_download_path(
        planning_application,
        format: "pdf"
      )
    )
  end
end
