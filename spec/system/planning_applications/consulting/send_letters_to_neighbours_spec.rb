# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Send letters to neighbours", js: true do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, local_authority: default_local_authority, api_user:)
  end

  before do
    ENV["OS_VECTOR_TILES_API_KEY"] = "testtest"
    allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(instance_double("response", status: 200, body: "some data")) # rubocop:disable RSpec/VerifiedDoubleReference
    allow_any_instance_of(Apis::OsPlaces::Query).to receive(:get).and_return(Faraday.new.get)

    sign_in assessor
    visit planning_application_path(planning_application)
  end

  it "displays the planning application address and reference" do
    expect(page).to have_content("2. Consultation")

    click_link "Send letters to neighbours"

    expect(page).to have_content("Send letters to neighbours")

    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)

    map_selector = find("my-map")
    expect(map_selector["latitude"]).to eq(planning_application.latitude)
    expect(map_selector["longitude"]).to eq(planning_application.longitude)
    expect(map_selector["showMarker"]).to eq("true")
  end

  it "allows me to add addresses" do
    click_link "Send letters to neighbours"

    fill_in "Add neighbours by address", with: "60-62 Commercial Street"
    # # Something weird is happening with the javascript, so having to double click for it to register
    # # This doesn't happen in "real life"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-62 Commercial Street")

    fill_in "Add neighbours by address", with: "60-61 Commercial Road"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-61 Commercial Road")

    expect(page).not_to have_content("Contacted neighbours")
  end

  it "allows me to edit addresses" do
    click_link "Send letters to neighbours"

    fill_in "Add neighbours by address", with: "60-62 Commercial Street"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-62 Commercial Street")

    click_link "Edit"

    fill_in "Address", with: "60-62 Commercial Road"
    click_button "Save"

    expect(page).to have_content("60-62 Commercial Road")
  end

  it "allows me to delete addresses" do
    click_link "Send letters to neighbours"

    fill_in "Add neighbours by address", with: "60-62 Commercial Street"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-62 Commercial Street")

    click_link "Remove"

    expect(page).not_to have_content("60-62 Commercial Street")
  end

  it "shows the status of letters that have been sent" do
    consultation = create(:consultation, planning_application:)
    neighbour = create(:neighbour, consultation:)
    neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id: "123")

    visit current_path
    stub_get_notify_status(notify_id: neighbour_letter.notify_id)

    click_link "Send letters to neighbours"

    expect(page).to have_content("Contacted neighbours")
    expect(page).to have_content(neighbour.address)
    expect(page).to have_content("Posted")

    fill_in "Add neighbours by address", with: "60-62 Commercial Street"
    page.find(:xpath, "//input[@value='Add neighbour']").click.click

    expect(page).to have_content("60-62 Commercial Street")
  end
end
