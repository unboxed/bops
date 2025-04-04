# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pre-application report" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:reviewer) { create(:user, :reviewer, local_authority:) }

  let(:planning_application) do
    create(
      :planning_application,
      :pre_application,
      :in_assessment,
      user: reviewer,
      local_authority:,
      validated_at: Time.zone.local(2024, 6, 1),
      determined_at: Time.zone.local(2024, 6, 20),
      description: "Single-storey rear extension"
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
end
