# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add conditions" do
  let!(:api_user) { create(:api_user, name: "PlanX") }
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority: default_local_authority, api_user:, decision: "granted")
  end

  before do
    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Check and assess"
  end

  context "when planning application is planning permission" do
    context "when it's been granted" do
      it "you can add conditions" do
        click_link "Add conditions"

        expect(page).to have_content("Add conditions")

        check "The development herby permitted shall be commenced within three years of the date of this permission"
        check "The development herby permitted must be undertaken in accordance with the approved plans and documents."

        click_button "Save and mark as complete"

        expect(page).to have_content "Conditions successfully created"

        within("#add-conditions") do
          expect(page).to have_content "Completed"
        end

        expect(planning_application.conditions.count).to eq 2
      end
    end
  end
end
