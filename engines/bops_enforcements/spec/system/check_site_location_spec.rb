# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check site location", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let(:submission) do
    create(
      :submission,
      :planning_portal,
      local_authority:,
      request_body: json_fixture_api("examples/odp/v0.7.5/enforcement/breach.json")
    )
  end
  let(:case_record) { build(:case_record, local_authority:, submission:) }
  let(:enforcement) { create(:enforcement, case_record:) }
  let(:user) { create(:user, local_authority:) }
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
    }
  end

  before do
    sign_in user
    visit "/enforcements/#{enforcement.reference}/check-breach-report"
    click_link "Check site location"
  end

  it "can be approved" do
    choose "Yes"
    click_button "Save and mark as complete"
    expect(page).to have_content "Successfully marked site location as correct"
    expect(enforcement.reload.valid_red_line_boundary).to be true
  end

  it "can be rejected then approved" do
    choose "No"
    click_button "Save and mark as complete"
    expect(page).to have_content "Marked site location as incorrect"

    expect(enforcement.reload.valid_red_line_boundary).to be false
    expect(current_url).to end_with("/edit")

    find("textarea[name='tasks_check_site_location_form[boundary_geojson]']").set(boundary_geojson.to_json)
    click_button "Save and mark as complete"
    expect(page).to have_content "Successfully updated site location"
    expect(enforcement.reload.valid_red_line_boundary).to be true
  end
end
