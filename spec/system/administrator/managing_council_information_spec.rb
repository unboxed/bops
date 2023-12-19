# frozen_string_literal: true

require "rails_helper"

RSpec.describe "managing council information profile" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:user) { create(:user, :administrator, local_authority:) }

  before do
    sign_in(user)
    visit "/administrator/local_authority"
  end

  it "allows the administrator to view council information profile" do
    expect(page).to have_content("Signatory name")

    expect(page).to have_content("Signatory job title")

    expect(page).to have_content("Enquiries paragraph")

    expect(page).to have_content("Decision notice email")

    expect(page).to have_content("Feedback email")

    expect(page).to have_content("Manager group email")

    expect(page).to have_content("Press notice email")

    expect(page).to have_content("Notify API key")

    expect(page).to have_content("Reply to_notify_id")

    expect(page).to have_content("Email reply_to_id")
  end

  it "allows the administrator to edit council information profile" do
    click_link("Edit profile")

    fill_in("Signatory name", with: "Andrew Drey")

    fill_in("Signatory job title", with: "Director")

    fill_in("Enquiries paragraph", with: "ssssss")

    fill_in("Decision notice email", with: "email@buckinghamshire.gov.uk")

    fill_in("Feedback email", with: "feedback_email@buckinghamshire.gov.uk")

    fill_in("Manager group email", with: "manager_email@buckinghamshire.gov.uk")

    fill_in("Press notice email", with: "press_notice_email@buckinghamshire.gov.uk")

    fill_in("Notify API key", with: "ssssss")

    fill_in("Reply to_notify_id", with: "ssssss")

    fill_in("Email reply_to_id", with: "ssssss")

    click_button("Submit")

    expect(page).to have_content("Council information successfully updated")
  end
end
