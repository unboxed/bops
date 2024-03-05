# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConditionSet do
  describe "#valid?" do
    let(:condition_set) { build(:condition_set) }

    it "is true for the default factory" do
      expect(condition_set.valid?).to be(true)
    end
  end

  describe "instance_methods" do
    describe "#approved_conditions" do
      let(:condition_set) { create(:condition_set) }

      let(:approved_condition) { create(:condition, condition_set:) }
      let(:eventually_approved_condition) { create(:condition, condition_set:) }
      let(:rejected_condition) { create(:condition, condition_set:) }

      before do
        create(:pre_commencement_condition_validation_request, owner: approved_condition, approved: true, state: "closed")
        create(:pre_commencement_condition_validation_request, owner: rejected_condition, approved: false, state: "closed", rejection_reason: "bad")
        create(:pre_commencement_condition_validation_request, owner: eventually_approved_condition, approved: true, state: "closed", notified_at: 1.day.ago)
        create(:pre_commencement_condition_validation_request, owner: eventually_approved_condition, approved: false, state: "closed", rejection_reason: "bad", notified_at: 2.days.ago)
      end

      it "returns conditions that have been approved" do
        expect(condition_set.approved_conditions).to include(approved_condition, eventually_approved_condition)
      end
    end
  end
end
