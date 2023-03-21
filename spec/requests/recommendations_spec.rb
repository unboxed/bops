# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Recommendations", show_exceptions: true do
  let!(:current_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, local_authority: current_local_authority) }
  let!(:recommendation) { create(:recommendation, planning_application:) }

  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }

  context "when reviewing the recommendation" do
    before { sign_in assessor }

    it "does not allow an assessor to view review form" do
      get edit_planning_application_recommendations_path(planning_application, recommendation)

      expect(response).to be_forbidden
    end

    it "does not allow an assessor to patch review" do
      patch planning_application_recommendation_path(planning_application, recommendation)

      expect(response).to be_forbidden
    end
  end
end
