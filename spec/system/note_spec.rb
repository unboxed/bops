# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Note" do
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:planning_application) { create(:planning_application, :not_started, local_authority:) }

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  it "has no notes by default" do
    click_link "Add a note"
    expect(page).to have_content("There are no notes yet.")
    expect(page).not_to have_content("Latest note")
    expect(page).not_to have_content("Previous note")
  end

  it "can add a note" do
    click_link "Add a note"
    fill_in "Add a note to this application.", with: "Remember the milk."
    click_button "Add new note"
    expect(page).to have_content("Note was successfully created.")
    expect(page).to have_content("Remember the milk.")
  end
end
