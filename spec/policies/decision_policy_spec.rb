# frozen_string_literal: true

require "rails_helper"

RSpec.describe DecisionPolicy, type: :policy do
  describe "All roles" do
    let(:record) { nil }
    let(:policy) { described_class.new(user, record) }

    %i[assessor reviewer].each do |role|
      context "when signed in as a #{role}" do
        let(:user) { create :user, role }

        %i[new create].each do |action|
          it "permits the '#{action}' action" do
            expect(policy).to permit_action(action)
          end
        end
      end
    end
  end
end
