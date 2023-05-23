# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Consulting" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, local_authority: default_local_authority, api_user:)
  end

  before do
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
end
