# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add conditions" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority, api_user:)
  end

  let!(:condtion) { create(:condition) }

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Check and assess"
  end

  context "when adding conditions" do
    it "displays the constraints" do
      click_link "Add conditions"

      expect(page).to have_content("Add conditions")

      check condition.title.to_s
    end
  end
end
