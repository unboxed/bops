# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PolicyEvaluationPolicy, type: :policy do
  describe "Assessor and Admin roles" do
    let(:record) { nil }
    let(:policy) { described_class.new(user, record) }

    %i[assessor admin].each do |role|
      context "when signed in as a #{role}" do
        let(:user) { create :user, role }

        %i[new create edit update].each do |action|
          it "permits the '#{action}' action" do
            expect(policy).to permit_action(action)
          end
        end
      end
    end
  end

  describe "Reviewer role" do
    let(:record) { nil }
    let(:policy) { described_class.new(user, record) }

    context "when signed in as a reviewer" do
      let(:user) { create :user, :reviewer }

      %i[new create edit update].each do |action|
        it "forbids the '#{action}' action" do
          expect(policy).to forbid_action(action)
        end
      end
    end
  end
end
