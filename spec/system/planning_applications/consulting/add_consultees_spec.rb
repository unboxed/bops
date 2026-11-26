# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consultation", type: :system, js: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:administrator) { create(:user, :administrator, local_authority:) }
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

  it "auto assigns consultees mapped to constraints" do
    suggested_contact = create(
      :contact,
      :external,
      local_authority:,
      name: "Historic England",
      email_address: "heritage@example.com"
    )

    constraint = planning_application.planning_application_constraints.first.constraint

    create(:consultee_constraint, consultee: suggested_contact, constraint:)

    perform_enqueued_jobs do
      create(:planning_application_constraint, planning_application:, constraint:)
    end

    click_link "Add and assign consultees"

    within(".govuk-summary-card:nth-of-type(3)") do
      expect(page).to have_content("Conservation area")
      expect(page).to have_content("Historic England")
    end
  end

  it "shows consultees linked to constraints via the admin interface" do
    constraint = planning_application.planning_application_constraints.first.constraint
    consultee = create(
      :contact,
      :external,
      local_authority:,
      name: "Historic England",
      email_address: "heritage@example.com"
    )

    sign_in(administrator)
    visit "/admin/consultees/#{consultee.id}/edit"
    find("summary", text: "More details").click
    check constraint.type_code
    click_button "Submit"
    expect(page).to have_content("Consultee successfully updated")

    perform_enqueued_jobs do
      create(:planning_application_constraint, planning_application:, constraint:)
    end

    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/consultation"

    click_link "Add and assign consultees"

    within(".govuk-summary-card:nth-of-type(3)") do
      expect(page).to have_content("Conservation area")
      expect(page).to have_content("Historic England")
    end
  end

  it "allows assigning multiple consultees and removing one" do
    click_link "Add and assign consultees"

    within(".govuk-summary-card:nth-of-type(1)") do
      expect(page).to have_content("Unassigned")
      click_link("Change")
    end

    expect(page).to have_selector("h1", text: "Conservation area")
    within_fieldset "Is consultation needed for this constraint?" do
      expect(page).to have_checked_field("Yes")

      fill_in "Search for a consultee", with: "Chris Wood"
      expect(page).to have_selector("#add-consultee__listbox li:first-child", text: "Chris Wood (Tree Officer, PlanX Council)")

      pick "Chris Wood (Tree Officer, PlanX Council)", from: "#add-consultee"
      expect(page).to have_field("Search for a consultee", with: "Chris Wood")

      click_button "Assign"
    end

    fill_in "Search for a consultee", with: "Consultations"
    pick "Consultations (Planning Department, GLA)", from: "#add-consultee"

    click_button "Assign"

    click_button "Save and return"

    within(".govuk-summary-card:nth-of-type(1)") do
      expect(page).not_to have_content("Unassigned")
      expect(page).to have_content("Chris Wood, Tree Officer")
      expect(page).to have_content("Consultations, Planning Department")

      click_link "Change"
    end

    within_fieldset "Is consultation needed for this constraint?" do
      accept_confirm do
        first(:link, "Remove").click
      end
    end

    expect(page).to have_content("Consultee was successfully removed from constraint")

    click_button "Save and return"

    within(".govuk-summary-card:nth-of-type(1)") do
      expect(page).not_to have_content("Chris Wood, Tree Officer")
      expect(page).to have_content("Consultations, Planning Department")
    end
  end

  it "allows marking a constraint as not requiring consultation" do
    within(".govuk-summary-card:nth-of-type(1)") do
      expect(page).to have_content("Unassigned")
      click_link("Change")
    end

    within_fieldset "Is consultation needed for this constraint?" do
      choose "No"
    end

    click_button "Save and return"
    expect(page).to have_content("Not needed")
  end
end
