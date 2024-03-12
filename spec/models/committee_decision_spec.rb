# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommitteeDecision do
  let(:committee_decision) { build(:committee_decision) }

  describe "#valid?" do
    it "is true for the default factory" do
      expect(committee_decision.valid?).to be(true)
    end
  end

  describe "validations" do
    describe "#recommend" do
      it "validates presence" do
        committee_decision.recommend = nil

        expect do
          committee_decision.valid?
        end.to change {
          committee_decision.errors[:recommend]
        }.to ["Select whether the application needs to go to committee"]
      end
    end

    describe "#reasons" do
      it "validates presence if it has been recommended" do
        committee_decision.recommend = true
        committee_decision.reasons = []

        expect do
          committee_decision.save
        end.to change {
          committee_decision.errors[:reasons]
        }.to ["Choose reasons why this application should go to committee"]
      end
    end
  end
end
