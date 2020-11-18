# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanningApplicationPolicy, type: :policy do
  let(:record) { nil }
  let(:policy) { described_class.new(user, record) }

  describe "Assessor, Reviewer and Admin roles" do
    %i[assessor reviewer admin].each do |role|
      context "when signed in as a #{role}" do
        let(:user) { create :user, role }

        %i[show index].each do |action|
          it "permits the '#{action}' action" do
            expect(policy).to permit_action(action)
          end
        end
      end
    end
  end

  describe "#permitted_statuses" do
    context "an assessor" do
      let(:user) {  create :user, :assessor }

      it "returns :awaiting_determination only" do
        expect(policy.permitted_statuses).to eq %w[ awaiting_determination ]
      end
    end

    context "a reviewer" do
      let(:user) {  create :user, :reviewer }

      it "returns :determined only" do
        expect(policy.permitted_statuses).to eq %w[ determined ]
      end
    end

    context "an admin" do
      let(:user) {  create :user, :admin }

      it "returns :determined only" do
        expect(policy.permitted_statuses).to eq %w[ determined ]
      end
    end
  end
end
