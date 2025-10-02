# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation", type: :system, js: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }
  let(:api_user) { create(:api_user, :planx) }
  let(:planning_application) do
    create(
      :planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :with_constraints,
      :published,
      application_type:,
      local_authority:,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com"
    )
  end

  def choose_consultee(search_term:, option_text:)
    field = find_field("Search for consultees")
    field.click
    fill_in "Search for consultees", with: search_term, fill_options: {clear: :backspace}
    expect(page).to have_selector(
      "#add-consultee__listbox li[role='option']",
      text: option_text
    )
    pick option_text, from: "#add-consultee"
    expected_value = option_text.split(" (").first
    expect(page).to have_field("Search for consultees", with: /\A#{Regexp.escape(expected_value)}/)
  end

  before do
    create(
      :contact, :external,
      name: "Consultations",
      role: "Planning Department",
      organisation: "GLA",
      email_address: "planning@london.gov.uk"
    )

    create(
      :contact, :internal,
      local_authority:,
      name: "Chris Wood",
      role: "Tree Officer",
      organisation: local_authority.council_name,
      email_address: "chris.wood@#{local_authority.subdomain}.gov.uk"
    )
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/consultation"
  end

  it "lists constraints on the selection page" do
    click_link "Add and assign consultees"

    conservation_row = row_with_content("Conservation area")
    listed_row = row_with_content("Listed building outline")

    expect(conservation_row).to have_text("Assign consultee")
    expect(listed_row).to have_text("Assign consultee")
  end

  it "allows adding a consultee" do
    click_link "Add and assign consultees"
    choose_consultee(
      search_term: "Tree Officer",
      option_text: "Chris Wood (Tree Officer, PlanX Council)"
    )

    click_button "Add consultee"

    expect(page).to have_selector(".govuk-table__row", text: "Other Chris Wood")
  end

  it "allows associating a consultee with a constraint" do
    click_link "Add and assign consultees"

    choose_consultee(
      search_term: "Tree Officer",
      option_text: "Chris Wood (Tree Officer, PlanX Council)"
    )
    click_button "Add consultee"

    within(row_with_content("Conservation area")) do
      click_link "Assign consultee"
    end
    expect(page).to have_unchecked_field("Chris Wood")
    check "Chris Wood"
    click_button "Assign consultees"

    row = row_with_content("Chris Wood")
    expect(row).to have_text("Chris Wood")
    expect(row).to have_selector(".govuk-tag", text: "Not consulted")
  end

  it "keeps existing consultees when toggling consultation required from the overview" do
    click_link "Add and assign consultees"

    choose_consultee(
      search_term: "Tree Officer",
      option_text: "Chris Wood (Tree Officer, PlanX Council)"
    )
    click_button "Add consultee"

    within(row_with_content("Conservation area")) do
      click_link "Assign consultee"
    end
    expect(page).to have_unchecked_field("Chris Wood")
    check "Chris Wood"
    click_button "Assign consultees"

    expect(page).to have_selector("tbody tr", text: "Chris Wood")

    within ".consultee-selection" do
      uncheck "Conservation area", allow_label_click: true
    end

    row = row_with_content("Conservation area")
    expect(row).to have_text("Chris Wood")
    expect(row).to have_selector(".govuk-tag", text: "Not required")

    within ".consultee-selection" do
      check "Conservation area", allow_label_click: true
    end

    row = row_with_content("Conservation area")
    expect(row).to have_text("Chris Wood")
  end

  it "allows assigning multiple consultees and removing one" do
    click_link "Add and assign consultees"

    choose_consultee(
      search_term: "Tree Officer",
      option_text: "Chris Wood (Tree Officer, PlanX Council)"
    )
    click_button "Add consultee"
    expect(page).to have_selector(".govuk-table__row", text: "Chris Wood")

    choose_consultee(
      search_term: "Consultations",
      option_text: "Consultations (Planning Department, GLA)"
    )
    click_button "Add consultee"

    within(row_with_content("Conservation area")) do
      click_link "Assign consultee"
    end

    expect(page).to have_unchecked_field("Chris Wood")
    expect(page).to have_unchecked_field("Consultations")
    check "Chris Wood"
    check "Consultations"
    click_button "Assign consultees"

    row = row_with_content("Conservation area")
    expect(row).to have_content("Chris Wood")
    expect(row).to have_content("Consultations")

    within(row) do
      click_link "Remove", match: :first
    end

    expect(row).not_to have_content("Chris Wood")
    expect(row).to have_content("Consultations")
  end

  it "allows marking a constraint as requiring consultation" do
    click_link "Add and assign consultees"

    choose_consultee(
      search_term: "Tree Officer",
      option_text: "Chris Wood (Tree Officer, PlanX Council)"
    )
    click_button "Add consultee"

    within(row_with_content("Conservation area")) do
      click_link "Assign consultee"
    end
    expect(page).to have_field("Consultation required?")

    check "Consultation required?"
    click_button "Assign consultees"

    expect(page).not_to have_selector(".govuk-table__row", text: "Not required")
  end

  it "allows marking a constraint as not requiring consultation" do
    click_link "Add and assign consultees"

    choose_consultee(
      search_term: "Tree Officer",
      option_text: "Chris Wood (Tree Officer, PlanX Council)"
    )
    click_button "Add consultee"

    within(row_with_content("Conservation area")) do
      click_link "Assign consultee"
    end
    expect(page).to have_field("Consultation required?")

    uncheck "Consultation required?"
    click_button "Assign consultees"

    within(row_with_content("Conservation area")) do
      expect(page).to have_link("Assign consultee")
      expect(page).to have_selector(".govuk-tag", text: "Not assigned")
      expect(page).to have_selector(".govuk-tag", text: "Not required")
    end
  end

  it "allows marking a constraint as not requiring consultation even with a consultee associated" do
    click_link "Add and assign consultees"

    choose_consultee(
      search_term: "Tree Officer",
      option_text: "Chris Wood (Tree Officer, PlanX Council)"
    )
    click_button "Add consultee"

    within(row_with_content("Conservation area")) do
      click_link "Assign consultee"
    end
    expect(page).to have_unchecked_field("Chris Wood")
    check "Chris Wood"
    uncheck "Consultation required?"
    click_button "Assign consultees"

    row = row_with_content("Chris Wood")
    expect(row).to have_selector(".govuk-tag", text: "Not consulted")
    expect(row).to have_selector(".govuk-tag", text: "Not required")
  end

  context "when no consultees are required" do
    before do
      planning_application.consultation.consultees.clear
      planning_application.planning_application_constraints.clear
    end

    it "allows marking as not requiring consultees" do
      visit "/planning_applications/#{planning_application.reference}/consultation"

      within "#consultee-tasks" do
        within "li:nth-child(1)" do
          expect(page).to have_selector("a", text: "Add and assign consultees")
          expect(page).to have_selector("strong", text: "Not started")
        end

        within "li:nth-child(2)" do
          expect(page).to have_selector("a", text: "Send emails to consultees")
          expect(page).to have_selector("strong", text: "Not started")
        end

        within "li:nth-child(3)" do
          expect(page).to have_selector("a", text: "View consultee responses")
          expect(page).to have_selector("strong", text: "Not started")
        end
      end

      click_link "Add and assign consultees"
      expect(page).to have_content("No reasons or constraints have been identified, so there are no suggested consultees.")

      click_button "Mark consultees as not required"
      expect(page).to have_content("Consultation was successfully updated")

      within "#consultee-tasks" do
        within "li:nth-child(1)" do
          expect(page).to have_selector("a", text: "Add and assign consultees")
          expect(page).to have_selector("strong", text: "Complete")
        end

        within "li:nth-child(2)" do
          expect(page).to have_selector("a", text: "Send emails to consultees")
          expect(page).to have_selector("strong", text: "Complete")
        end

        within "li:nth-child(3)" do
          expect(page).to have_selector("a", text: "View consultee responses")
          expect(page).to have_selector("strong", text: "Complete")
        end
      end
    end
  end
end
