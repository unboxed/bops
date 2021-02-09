# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning applications", type: :request, show_exceptions: true do
  let!(:current_local_authority) { @default_local_authority }
  let!(:other_local_authority) { create(:local_authority) }

  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }

  let!(:planning_application) { create(:planning_application, local_authority: other_local_authority) }

  # TODO: add the rest of the actions on planning application controller
  it "returns 404 when trying to get show for a planning application on another local authority" do
    sign_in assessor
    expect {
      get planning_application_path(planning_application)
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
