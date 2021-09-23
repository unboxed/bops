# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Policy classes", type: :request, show_exceptions: true do
  let!(:current_local_authority) { @default_local_authority }
  let!(:planning_application) { create(:planning_application, :determined, local_authority: current_local_authority) }
  let!(:policy_class) { build(:policy_class) }
  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }

  before do
    policy_class.stamp_part!(1)
  end

  it "does not allow updating classes past assessment" do
    sign_in assessor

    params = {
      part: policy_class.part,
      policy_classes: [
        policy_class.id,
      ],
    }

    post planning_application_policy_classes_path(planning_application), params: params
    expect(response).to redirect_to new_planning_application_policy_class_path(planning_application, part: 1)

    follow_redirect!

    expect(response.body).to include "Policy classes cannot be added at this stage"
  end
end
