# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning applications", show_exceptions: true do
  let!(:current_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) { create(:planning_application, local_authority: current_local_authority) }

  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }

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
