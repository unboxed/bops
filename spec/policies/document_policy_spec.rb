# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentPolicy, type: :policy do
  describe "Assessor and Reviewer roles" do
    let(:record) { nil }
    let(:policy) { described_class.new(user, record) }

    %i[assessor reviewer].each do |role|
      context "when signed in as a #{role}" do
        let(:user) { create :user, role }

        %i[index].each do |action|
          it "permits the '#{action}' action" do
            expect(policy).to permit_action(action)
          end
        end
      end
    end
  end
end
