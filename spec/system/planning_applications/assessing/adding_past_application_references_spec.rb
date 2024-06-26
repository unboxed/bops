# frozen_string_literal: true

require "rails_helper"

RSpec.describe "adding past application references" do
  let(:default_local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(:user, :assessor, local_authority: default_local_authority)
  end

  let!(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      local_authority: default_local_authority
    )
  end

  it "lets user save draft, mark as complete, and edit" do
    sign_in(assessor)
    visit "/planning_applications/#{planning_application.id}"
    click_link("Check and assess")

    expect(list_item("History (manual)")).to have_content("Not started")

    click_link("History (manual)")
    fill_in("Add any relevant reference numbers. You can separate the reference numbers with a comma.", with: "22-00107-LDCP")
    click_button("Save and mark as complete")

    expect(page).to have_content("Relevant information can't be blank")

    click_button("Save and come back later")

    expect(page).to have_content("History successfully added.")
    expect(list_item("History (manual)")).to have_content("In progress")

    click_link("History (manual)")
    fill_in("Provide relevant information about the planning history of the application site", with: "Application granted.")
    click_button("Save and mark as complete")

    expect(page).to have_content("History successfully updated.")
    expect(list_item("History (manual)")).to have_content("Completed")

    click_link("History (manual)")

    expect(page).to have_content("22-00107-LDCP")
    expect(page).to have_content("Application granted.")

    click_link("Edit history")
    fill_in("Add any relevant reference numbers. You can separate the reference numbers with a comma.", with: "22-00108-LDCP")
    click_button("Save and mark as complete")

    expect(page).to have_content("History successfully updated.")

    click_link("History (manual)")

    expect(page).to have_content("22-00108-LDCP")
  end
end
