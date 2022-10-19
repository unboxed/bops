# frozen_string_literal: true

require "rails_helper"

RSpec.describe "adding past application references", type: :system do
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
    visit(planning_application_path(planning_application))
    click_link("Check and assess")

    expect(list_item("History (manual)")).to have_content("Not started")

    click_link("History (manual)")
    fill_in("Relevant information", with: "Application granted.")
    click_button("Save and mark as complete")

    expect(page).to have_content(
      "Application reference numbers can't be blank"
    )

    click_button("Save and come back later")

    expect(page).to have_content("History successfully added.")
    expect(list_item("History (manual)")).to have_content("In progress")

    click_link("History (manual)")
    fill_in("Application reference number(s)", with: "22-00107-LDCP")
    click_button("Save and mark as complete")

    expect(page).to have_content("History successfully updated.")
    expect(list_item("History (manual)")).to have_content("Complete")

    click_link("History (manual)")

    expect(page).to have_content("22-00107-LDCP")
    expect(page).to have_content("Application granted.")

    click_link("Edit history")
    fill_in("Application reference number(s)", with: "22-00108-LDCP")
    click_button("Save and mark as complete")

    expect(page).to have_content("History successfully updated.")

    click_link("History (manual)")

    expect(page).to have_content("22-00108-LDCP")
  end
end
