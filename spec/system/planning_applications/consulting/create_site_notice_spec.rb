# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Create a site notice" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  let!(:planning_application) do
    create(:planning_application,
           :from_planx_prior_approval,
           :with_boundary_geojson,
           application_type:,
           local_authority: default_local_authority,
           api_user:,
           agent_email: "agent@example.com",
           applicant_email: "applicant@example.com",
           make_public: true)
  end

  before do
    sign_in(assessor)

    visit planning_application_path(planning_application)
  end

  it "allows officers to create a site notice and print it" do
    click_link "Create site notice"

    choose "Yes"

    choose "Create, print and post a PDF (opens in a new tab)"

    click_button "Create site notice"
  end

  it "allows officers to create a site notice and email it to the applicant" do
    click_link "Create site notice"

    choose "Yes"

    choose "Send it by email to applicant"

    click_button "Create site notice"
  end

  it "allows officers to create a site notice and email it to the internal team" do
    click_link "Create site notice"

    choose "Yes"

    choose "Send it by email to internal team to post"

    click_button "Create site notice"
  end


  it "allows officers to confirm site notice is not needed" do
    click_link "Create site notice"

    choose "No"

    click_button "Create site notice"

    expect(page).not_to have_content "Confirm site notice is in place"
  end
end
