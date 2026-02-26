# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting other changes to a planning application" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority)
  end

  let!(:api_user) { create(:api_user, :validation_requests_ro) }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
  end

  context "when there are fee item validation requests" do
    let!(:other_change_validation_request) do
      create(:other_change_validation_request, planning_application:)
    end
    let!(:fee_change_validation_request) do
      create(:fee_change_validation_request, planning_application:)
    end

    it "does not show in the other validation issues task list" do
      visit "/planning_applications/#{planning_application.reference}/validation"
      click_link "Other validation requests"

      expect(page).to have_link(
        other_change_validation_request.reason,
        href: "/planning_applications/#{planning_application.reference}/validation/validation_requests/#{other_change_validation_request.id}?redirect_to=%2Fplanning_applications%2F#{planning_application.reference}%2Fcheck-and-validate%2Fother-validation-issues%2Fother-validation-requests"
      )
      expect(page).not_to have_link(
        fee_change_validation_request.reason,
        href: "/planning_applications/#{planning_application.reference}/validation/validation_requests/#{fee_change_validation_request.id}?redirect_to=%2Fplanning_applications%2F#{planning_application.reference}%2Fcheck-and-validate%2Fother-validation-issues%2Fother-validation-requests"
      )
    end
  end
end
