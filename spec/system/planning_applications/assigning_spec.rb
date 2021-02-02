# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assigning a planning application", type: :system do
  let(:local_authority) { @default_local_authority }
  let!(:assessor1) { create :user, :assessor, local_authority: local_authority, name: "Assessor 1" }
  let!(:assessor2) { create :user, :assessor, local_authority: local_authority, name: "Assessor 2" }
  let!(:planning_application) { create :planning_application, local_authority: local_authority, user: assessor1 }

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
    click_button "Assign"
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
    click_button "Assign"
    within ".assigned_to" do
      expect(page).to have_text("Unassigned")
    end
  end
end
