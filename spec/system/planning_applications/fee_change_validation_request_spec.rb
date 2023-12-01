# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting other changes to a planning application" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority)
  end

  let!(:api_user) { create(:api_user, name: "Api Wizard") }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
  end

  context "when there are fee item validation requests" do
    let!(:other_change_validation_request) do
      create(:other_change_validation_request, planning_application:)
    end
    let!(:fee_change_validation_request) do
      create(:fee_change_validation_request, planning_application:)
    end

    it "does not show in the other validation issues task list" do
      visit "/planning_applications/#{planning_application.id}/validation/tasks"
      within("#other-change-validation-tasks") do
        expect(page).to have_link(
          "View other validation request ##{other_change_validation_request.sequence}",
          href: planning_application_validation_validation_request_path(planning_application, other_change_validation_request)
        )
        expect(page).not_to have_link(
          "View other validation request ##{fee_change_validation_request.sequence}",
          href: planning_application_validation_validation_request_path(planning_application, fee_change_validation_request)
        )
      end
    end
  end
end
