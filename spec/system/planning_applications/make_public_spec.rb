# frozen_string_literal: true

require "rails_helper"

RSpec.describe "making planning application public" do
  let(:local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(
      :user,
      :assessor,
      local_authority:,
      name: "Jane Smith"
    )
  end

  let(:planning_application) do
    create(
      :planning_application,
      local_authority:
    )
  end

  it "lets a planning application be made public and not" do
    travel_to("2022-01-01")
    sign_in(assessor)

    visit "/planning_applications/#{planning_application.reference}"

    expect(page).to have_content("Public on BOPS Public Portal: No")

    visit "/planning_applications/#{planning_application.reference}/make_public"

    expect(page).to have_content("Make application public")

    choose "Yes"

    click_button "Update application"

    expect(page).to have_content("Public on BOPS Public Portal: Yes")

    expect(planning_application.reload.published_at).to eq(Time.zone.local(2022, 1, 1))

    visit "/planning_applications/#{planning_application.reference}/make_public"

    choose "No"

    click_button "Update application"

    expect(page).to have_content("Public on BOPS Public Portal: No")

    expect(planning_application.reload.published_at).to be_nil
  end
end
