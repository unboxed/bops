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

    visit(planning_application_path(planning_application))

    expect(page).to have_content("Application is not public on BoPS applicants")

    visit(make_public_planning_application_path(planning_application))

    expect(page).to have_content("Make application public")

    check "Publish application on BoPS applicants?"

    click_button "Update application"

    expect(page).to have_content("Application is public on BoPS applicants")

    visit(make_public_planning_application_path(planning_application))

    uncheck "Publish application on BoPS applicants?"

    click_button "Update application"

    expect(page).to have_content("Application is not public on BoPS applicants")
  end
end
