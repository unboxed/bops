# frozen_string_literal: true

require "rails_helper"

RSpec.describe "adding consultation summary" do
  let(:default_local_authority) { create(:local_authority, :default) }

  let!(:assessor) do
    create(:user, :assessor, local_authority: default_local_authority)
  end

  let!(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      :planning_permission,
      local_authority: default_local_authority
    )
  end

  let!(:consultation) do
    planning_application.consultation
  end

  let!(:alice_smith) do
    create(:consultee, :internal, :with_response, name: "Alice Smith", consultation:)
  end

  let!(:bella_jones) do
    create(:consultee, :external, :with_response, name: "Bella Jones", consultation:)
  end

  before do
    sign_in(assessor)
    visit(planning_application_path(planning_application))
    click_link("Check and assess")
  end

  it "lets user save draft, mark as complete, and edit" do
    expect(list_item("Summary of consultation")).to have_content("Not started")

    click_link("Summary of consultation")
    click_button("Save and mark as complete")

    expect(page).to have_content(
      "Summary of consultation responses can't be blank"
    )

    within "#consultation-responses" do
      expect(page).to have_content("Alice Smith")
      expect(page).to have_content("Bella Jones")
    end

    click_button("Save and come back later")

    expect(page).to have_content("Consultation summary successfully added.")
    expect(list_item("Summary of consultation")).to have_content("In progress")

    click_link("Summary of consultation")
    fill_in("Summary of consultation responses", with: "Lorem ipsum")
    click_button("Save and mark as complete")

    expect(page).to have_content("Consultation summary successfully updated.")
    expect(list_item("Summary of consultation")).to have_content("Completed")

    click_link("Summary of consultation")

    within "#consultation-responses" do
      expect(page).to have_content("Alice Smith")
      expect(page).to have_content("Bella Jones")
    end

    expect(page).to have_content("Lorem ipsum")

    click_link("Edit consultation details")
    fill_in("Summary of consultation responses", with: "dolor sit amet")
    click_button("Save and mark as complete")

    expect(page).to have_content("Consultation summary successfully updated.")
  end
end
