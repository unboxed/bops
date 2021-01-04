# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplicationPolicy, type: :policy do
  let(:local_authority) { create :local_authority }
  let(:local_authority_two) { create :local_authority, name: "Imaginary Council" }
  let(:record) { create :planning_application, local_authority: local_authority }
  let(:policy) { described_class.new(user, record) }
  let(:policy_two) { described_class.new(user_two_forbidden, record) }

  describe "Assessor and Reviewer roles" do
    %i[assessor reviewer].each do |role|
      context "when signed in to the domain as #{role}" do
        let(:user) { create :user, role, local_authority: local_authority }

        %i[show index].each do |action|
          it "permits the '#{action}' action if the user and record belong to the same local authority" do
            expect(policy).to permit_action(action)
          end
        end
      end

      context "when signed in to the domain as #{role} from another domain" do
        let(:user_two_forbidden) { create :user, role, local_authority: local_authority_two }

        %i[show index].each do |action|
          it "forbids the '#{action}' action if the user and record do not belong to the same local authority" do
            expect(policy_two).not_to permit_action(action)
          end
        end
      end
    end
  end

  describe "#permitted_statuses" do
    context "an assessor" do
      let(:user) { create :user, :assessor, local_authority: local_authority }

      it "returns :awaiting_determination only" do
        expect(policy.permitted_statuses).to eq %w[awaiting_determination]
      end
    end

    context "a reviewer" do
      let(:user) { create :user, :reviewer, local_authority: local_authority }

      it "returns :determined only" do
        expect(policy.permitted_statuses).to eq %w[determined]
      end
    end
  end
end
