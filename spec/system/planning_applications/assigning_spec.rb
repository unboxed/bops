# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assigning a planning application", type: :system do
  let!(:assessor1) { create :user, :assessor, local_authority: @default_local_authority, name: "Assessor 1" }
  let!(:assessor2) { create :user, :assessor, local_authority: @default_local_authority, name: "Assessor 2" }
  let!(:planning_application) do
    create :planning_application, local_authority: @default_local_authority, user: assessor1
  end

  before do
    sign_in assessor1
    visit planning_application_path(planning_application)
  end

  it "is possible to assign to a user" do
    within ".assigned_to" do
      expect(page).to have_text("Assessor 1")
      click_link "Change"
    end
    choose "Assessor 2"
    click_button "Confirm"
    within ".assigned_to" do
      expect(page).to have_text("Assessor 2")
    end
  end

  it "is possible to assign to nobody" do
    within ".assigned_to" do
      expect(page).to have_text("Assessor 1")
      click_link "Change"
    end
    choose "Unassigned"
    click_button "Confirm"
    within ".assigned_to" do
      expect(page).to have_text("Unassigned")
    end
  end

  it "creates an audit entry all assigning actions" do
    within ".assigned_to" do
      click_link "Change"
    end
    choose "Assessor 2"
    click_button "Confirm"

    within ".assigned_to" do
      click_link "Change"
    end
    choose "Unassigned"
    click_button "Confirm"

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Application assigned to Assessor 2")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))

    expect(page).to have_text("Application unassigned")
    expect(page).to have_text(Audit.second_to_last.created_at.strftime("%d-%m-%Y %H:%M"))
  end
end
