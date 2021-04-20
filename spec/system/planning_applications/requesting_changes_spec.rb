# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting changes to a planning application", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :invalidated, local_authority: @default_local_authority
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
  end

  it "is possible to create a request to update description" do
    click_link "Validate application"
    click_link "New request(s)"
    fill_in "Please suggest a new application description", with: "New description"
    click_button "Send"
    within(".change_requests") do
      expect(page).to have_content("Description")
      expect(page).to have_content("15 days")
      expect(page).to have_content("Open")
    end
  end

  it "only accepts a request that contains a proposed description" do
    click_link "Validate application"
    click_link "New request(s)"
    fill_in "Please suggest a new application description", with: " "
    click_button "Send"

    expect(page).to have_content("Proposed description can't be blank")
  end

  it "lists the current change requests and their statuses" do
    create :description_change_request, planning_application: planning_application, state: "open", created_at: 12.days.ago
    create :description_change_request, planning_application: planning_application, state: "closed", created_at: 12.days.ago, approved: true
    create :description_change_request, planning_application: planning_application, state: "closed", created_at: 12.days.ago, approved: false
    create :description_change_request, planning_application: planning_application, state: "open", created_at: 30.days.ago

    click_link "Validate application"
    within(".change_requests") do
      expect(page).to have_content("3 days")
      expect(page).to have_content("Open")

      expect(page).to have_content("Closed")
      expect(page).to have_content("Approved")

      expect(page).to have_content("Closed")
      expect(page).to have_content("Rejected")

      expect(page).to have_content("-15 days")
      expect(page).to have_content("Open")
    end
  end
end
