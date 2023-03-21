# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Policy classes", show_exceptions: true do
  let!(:current_local_authority) { create(:local_authority, :default) }
  let!(:planning_application) do
    create(:planning_application, :in_assessment, local_authority: current_local_authority)
  end
  let!(:policy_class) { build(:policy_class) }
  let!(:assessor) { create(:user, :assessor, local_authority: current_local_authority) }

  before do
    sign_in assessor
  end

  it "validates selecting a part" do
    get new_planning_application_policy_class_path(planning_application)

    expect(response).to redirect_to part_new_planning_application_policy_class_path(planning_application)
    follow_redirect!

    expect(response.body).to include "Please choose one of the policy parts"
  end

  it "redirects successfully even when no classes are selected" do
    params = {
      part: policy_class.part,
      policy_classes: []
    }

    post(planning_application_policy_classes_path(planning_application), params:)

    expect(response).to redirect_to planning_application_assessment_tasks_path(planning_application)
    follow_redirect!

    expect(response.body).to include "Policy classes have been successfully added"
  end

  context "when the application is past assessment" do
    let!(:planning_application) { create(:planning_application, :determined, local_authority: current_local_authority) }

    it "does not allow updating classes past assessment" do
      params = {
        part: policy_class.part,
        policy_classes: [
          policy_class.id
        ]
      }

      post(planning_application_policy_classes_path(planning_application), params:)

      expect(response).to be_forbidden
    end
  end
end
