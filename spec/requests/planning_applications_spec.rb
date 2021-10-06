# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning applications", type: :request, show_exceptions: true do
  let!(:current_local_authority) { @default_local_authority }
  let!(:planning_application) { create(:planning_application, local_authority: current_local_authority) }

  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }

  it "does not allow assessor to view review form" do
    sign_in assessor
    get review_form_planning_application_path(planning_application)
    expect(response).to be_forbidden
  end

  it "does not allow assessor to patch review" do
    sign_in assessor
    patch review_planning_application_path(planning_application)
    expect(response).to be_forbidden
  end

  context "belongs to another local authority" do
    let!(:other_local_authority) { create(:local_authority) }
    let!(:planning_application) { create(:planning_application, local_authority: other_local_authority) }

    it "returns 404 when trying to get show for a planning application" do
      sign_in assessor
      expect do
        get planning_application_path(planning_application)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
