# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pre-application report" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create(:user, :reviewer, local_authority:) }
  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority:,
      name: "Jane Smith"
    )
  end

  let(:boundary_geojson) do
    {
      type: "Feature",
      properties: {},
      geometry: {
        type: "Polygon",
        coordinates: [
          [
            [-0.054597, 51.537331],
            [-0.054588, 51.537287],
            [-0.054453, 51.537313],
            [-0.054597, 51.537331]
          ]
        ]
      }
    }.to_json
  end

  let(:planning_application) do
    create(
      :planning_application,
      :pre_application,
      :in_assessment,
      user: reviewer,
      local_authority:,
      boundary_geojson:,
      validated_at: Time.zone.local(2024, 6, 1),
      determined_at: Time.zone.local(2024, 6, 20),
      description: "Single-storey rear extension",
      recommended_application_type: create(:application_type, :householder)
    )
  end

  let!(:site_visit) do
    create(:site_visit, planning_application:, visited_at: Time.zone.local(2024, 6, 10))
  end
  let!(:meeting) do
    create(:meeting, planning_application:, occurred_at: Time.zone.local(2024, 6, 15))
  end

  let!(:assessment_detail) { create(:assessment_detail, planning_application:) }

  let!(:summary_of_advice) do
    create(:assessment_detail, planning_application:, category: "summary_of_advice", summary_tag: "complies", entry: "Looks good")
  end

  let(:report_url) { "/reports/planning_applications/#{planning_application.reference}" }
  let!(:site_history) { create(:site_history, planning_application:) }

  let!(:site_description) do
    create(:assessment_detail, planning_application:, category: "site_description", entry: "A double storey detached house adjacent to greenbelt.")
  end

  let!(:consistency_checklist) do
    create(:consistency_checklist, :site_map_incorrect, planning_application:)
  end

  let!(:designated_conservation_area) do
    create(:planning_application_constraint, planning_application:)
  end

  let!(:tpo) { create(:constraint, :tpo) }

  let!(:planning_application_constraint) do
    create(:planning_application_constraint, constraint: tpo, planning_application:)
  end

  let(:report_url) { "/planning_applications/#{planning_application.reference}" }

  before do
    sign_in reviewer
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
    click_link "Review and submit pre-application"
  end

  it "shows the report content and table of contents" do
    expect(page).to have_content("Pre-application report")
    expect(page).to have_content("This report gives clear guidance on your proposal")
    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content("Pre-application number: #{planning_application.reference}")
    expect(page).to have_content("Case officer: #{reviewer.name}")
    expect(page).to have_content("Date of report: #{planning_application.determined_at.to_date.to_fs}")

    within(".bops-table-of-contents") do
      expect(page).to have_link("Pre-application outcome", href: "#pre-application-outcome")
      expect(page).to have_link("Your pre-application details", href: "#pre-application-details")
      expect(page).to have_link("Site map", href: "#site-map")
      expect(page).to have_link("Site constraints", href: "#site-constraints")
      expect(page).to have_link("Site history", href: "#site-history")
      expect(page).to have_link("Site and surroundings", href: "#site-and-surroundings")
    end
  end

  it "displays the summary of advice outcome section" do
    within("#pre-application-outcome") do
      expect(page).to have_content("Pre-application outcome")
      expect(page).to have_link("Edit", href: "/planning_applications/#{planning_application.reference}/assessment/assessment_details/#{summary_of_advice.id}/edit?category=summary_of_advice&return_to=report")
      expect(page).to have_css(".govuk-notification-banner.bops-notification-banner--green")
      expect(page).to have_content("Likely to be supported")
    end
  end

  it "displays the officer contact details" do
    within("#contact-details") do
      expect(page).to have_content(reviewer.name)
      expect(page).to have_content(reviewer.email)
      expect(page).to have_content(reviewer.mobile_number)
    end
  end

  it "allows the user to assign case officer if not set" do
    planning_application.update(user: nil)
    visit "/reports/planning_applications/#{planning_application.reference}"

    within("#contact-details") do
      expect(page).to have_content("No case officer has been assigned yet.")
      click_link("Assign case officer")
    end

    select("Jane Smith")
    click_button("Confirm")

    within("#contact-details") do
      expect(page).to have_content("Jane Smith")
      expect(page).to have_content(assessor.email)
      expect(page).to have_content(assessor.mobile_number)
    end
  end

  it "displays pre-application details table" do
    within("#pre-application-details-table") do
      rows = all("tbody tr")

      within(rows[0]) do
        expect(page).to have_content("Date made valid")
        expect(page).to have_content(planning_application.validated_at.to_date.to_fs)
        expect(page).not_to have_link("Edit")
      end

      within(rows[1]) do
        expect(page).to have_content("Site visit")
        expect(page).to have_content(planning_application.site_visit_visited_at.to_date.to_fs)
        expect(page).to have_link("Edit", href: "/planning_applications/#{planning_application.reference}/assessment/site_visits?return_to=report")
      end

      within(rows[2]) do
        expect(page).to have_content("Meeting")
        expect(page).to have_content(planning_application.meeting_occurred_at.to_date.to_fs)
        expect(page).to have_link("Edit", href: "/planning_applications/#{planning_application.reference}/assessment/meetings?return_to=report")
      end
    end
  end

  it "displays the proposal description" do
    expect(page).to have_content("Description of your proposal")
    expect(page).to have_content("Single-storey rear extension")
  end

  it "has a back link to the application page" do
    expect(page).to have_link("Back", href: "/planning_applications/#{planning_application.reference}")
  end

  it "returns to the report page after editing summary of advice" do
    within("#pre-application-outcome") do
      click_link "Edit"
    end

    fill_in "Enter summary of planning considerations and advice", with: "Updated advice."
    choose "Likely to be supported with changes"
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/reports/planning_applications/#{planning_application.reference}")
    expect(page).to have_content("Likely to be supported with changes")
    expect(page).to have_css(".govuk-notification-banner.bops-notification-banner--orange")
  end

  it "returns to the report page after adding a new meeting" do
    within("#pre-application-details-table") do
      click_link "Edit", href: "/planning_applications/#{planning_application.reference}/assessment/meetings?return_to=report"
    end

    toggle "Add a new meeting"
    fill_in "Day", with: "2"
    fill_in "Month", with: "4"
    fill_in "Year", with: "2025"
    fill_in "Add notes (optional)", with: "Discussed next steps"
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/reports/planning_applications/#{planning_application.reference}")
    within("#pre-application-details-table") do
      rows = all("tbody tr")

      within(rows[2]) do
        expect(page).to have_content("2 April 2025")
      end
    end
  end

  it "returns to the report page after viewing site visits" do
    within("#pre-application-details-table") do
      click_link "Edit", href: "/planning_applications/#{planning_application.reference}/assessment/site_visits?return_to=report"
    end

    click_link "Back"

    expect(page).to have_current_path("/reports/planning_applications/#{planning_application.reference}")
  end

  it "returns to the report page after editing proposal description" do
    within("#proposal-description") do
      expect(page).to have_content("Single-storey rear extension")
      click_link "Edit"
    end

    fill_in "Enter an amended description", with: "This is the amended description for the proposal"
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/reports/planning_applications/#{planning_application.reference}")
    within("#proposal-description") do
      expect(page).to have_content("This is the amended description for the proposal")
    end
  end

  it "displays site map" do
    within("#site-map") do
      expect(page).to have_content("Site map")
      expect(page).to have_content("This map shows the area of the proposed development. It has been checked by the case officer.")

      within("#officer-map-comments") do
        expect(page).to have_content("Officer comments")
        expect(page).to have_content("Site map is of neighbours property")
      end
    end
  end

  it "returns to report after editing site map comment" do
    within("#officer-map-comments") do
      click_link "Edit"
    end

    fill_in "consistency-checklist-site-map-correct-comment-field", with: "Site map is of neighbours property, this comment has been updated."

    click_button "Save and mark as complete"
    expect(page).to have_content("Successfully updated application checklist")
    expect(page).to have_current_path("/reports/planning_applications/#{planning_application.reference}")

    within("#officer-map-comments") do
      expect(page).to have_content("Site map is of neighbours property, this comment has been updated.")
    end
  end

  it "displays site constraints" do
    within("#site-constraints") do
      expect(page).to have_content("Relevant site constraints")
      expect(page).to have_content("Site constraints are factors that could affect the development, such as zoning, environmental protections, or nearby conservation areas.")

      within("#site-constraints-heritage_and_conservation") do
        expect(page).to have_content("Heritage and conservation")
        expect(page).to have_content("Designated conservationarea")
      end

      within("#site-constraints-trees") do
        expect(page).to have_content("Trees")
        expect(page).to have_content("Tpo")
      end
    end
  end

  it "returns to report after editing site constraints" do
    within("#site-constraints") do
      click_link "Edit"
    end

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/validation/constraints?return_to=report")
    expect(page).to have_content("Check the constraints")

    within(".identified-constraints-table") do
      expect(page).to have_text("Conservation area")
      within(row_with_content("Tree preservation zone")) do
        click_link "Remove"
      end
    end
    expect(page).to have_content("Constraint was successfully removed")

    click_button "Save and mark as complete"

    expect(page).to have_current_path("/reports/planning_applications/#{planning_application.reference}")
    expect(page).to have_content("Constraints were successfully checked")

    within("#site-constraints") do
      expect(page).not_to have_content("Trees")
    end
  end

  it "displays site history" do
    within("#site-history") do
      expect(page).to have_content("Relevant site history")
      expect(page).to have_content("Past applications for this site or relevant nearby locations")

      within(".govuk-summary-card") do
        expect(page).to have_content("REF123")
        expect(page).to have_content("An entry for planning history")
      end
    end
  end

  it "returns to report page after editing site history" do
    within("#site-history") do
      click_link "Edit"
    end

    expect(page).to have_current_path("/planning_applications/#{planning_application.reference}/assessment/site_histories?return_to=report")

    within(".planning-history-table") do
      within(row_with_content("REF123")) do
        click_link "Edit"
      end
    end

    fill_in "site-history-comment-field", with: "An amended entry for planning history"

    click_button "Update site history"

    expect(page).to have_content("Site history was successfully updated")
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/reports/planning_applications/#{planning_application.reference}")
    expect(page).to have_content("Site history has been confirmed")

    within("#site-history") do
      expect(page).to have_content("Officer comment: An amended entry for planning history")
    end
  end

  it "displays site and surroundings" do
    within("#site-and-surroundings") do
      expect(page).to have_content("Site and surroundings")
      expect(page).to have_content("A double storey detached house adjacent to greenbelt.")
    end
  end

  it "returns to report page after editing site and surroundings" do
    within("#site-and-surroundings") do
      click_link "Edit"
    end

    expect(page).to have_content("Edit site description")

    fill_in "assessment_detail[entry]", with: "This is the amended description of site and surroundings"
    click_button "Save and mark as complete"

    expect(page).to have_current_path("/reports/planning_applications/#{planning_application.reference}")
    within("#site-and-surroundings") do
      expect(page).to have_content("This is the amended description of site and surroundings")
    end
  end

  it "displays next steps and disclaimer" do
    local_authority.update(submission_guidance_url: "https://www.southwark.gov.uk/planning-and-building-control/planning-policy-and-guidance")

    visit "/reports/planning_applications/#{planning_application.reference}"
    within("#next-steps") do
      expect(page).to have_content("If you wish to submit an application, follow these clear steps to submit your formal application:")
      expect(page).to have_link("website", href: "https://www.southwark.gov.uk/planning-and-building-control/planning-policy-and-guidance")
      expect(page).to have_content("For further information on applying to the 'Householder Application for Planning Permission' application, visit the council's website.")
    end

    # Default disclaimer
    within("#disclaimer") do
      within(".govuk-warning-text") do
        expect(page).to have_content("Please note that this pre-application advice follows initial officer assessment of the information you have provided.")
      end
    end

    # With custom disclaimer
    planning_application.application_type.update(disclaimer: "This is a custom disclaimer")
    visit "/reports/planning_applications/#{planning_application.reference}"
    within("#disclaimer") do
      within(".govuk-warning-text") do
        expect(page).to have_content("This is a custom disclaimer")
      end
    end
  end
end
