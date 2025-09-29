# frozen_string_literal: true

require "rails_helper"

RSpec.describe SiteHistory do
  describe "validations" do
    it "has a valid factory" do
      expect(build(:site_history)).to be_valid
    end

    it "validates the presence of a reference" do
      expect(build(:site_history, reference: nil)).to be_invalid
    end

    it "validates the presence of a description" do
      expect(build(:site_history, description: nil)).to be_invalid
    end

    it "validates the presence of a decision" do
      expect(build(:site_history, decision: nil)).to be_invalid
    end

    it "validates the presence of a date" do
      expect(build(:site_history, date: nil)).to be_invalid
    end

    it "does not validate the presence of an address" do
      expect(build(:site_history, address: nil)).to be_valid
    end

    it "allows dates in the past" do
      expect(build(:site_history, date: Date.yesterday)).to be_valid
    end

    it "allows today's date" do
      expect(build(:site_history, date: Date.current)).to be_valid
    end

    it "doesn't allow dates in the future" do
      expect(build(:site_history, date: Date.tomorrow)).to be_invalid
    end
  end

  describe "#decision_label" do
    let(:site_history) { build(:site_history, decision:) }

    context "when the decision is 'granted'" do
      let(:decision) { "granted" }

      it "returns 'Granted'" do
        expect(site_history.decision_label).to eq("Granted")
      end
    end

    context "when the decision is 'not_required'" do
      let(:decision) { "not_required" }

      it "returns 'Not required'" do
        expect(site_history.decision_label).to eq("Not required")
      end
    end

    context "when the decision is 'refused'" do
      let(:decision) { "refused" }

      it "returns 'Refused'" do
        expect(site_history.decision_label).to eq("Refused")
      end
    end

    context "when the decision is not a standard value" do
      let(:decision) { "Application Permitted" }

      it "returns the original decision" do
        expect(site_history.decision_label).to eq("Application Permitted")
      end
    end
  end

  describe "#decision_type" do
    let(:site_history) { build(:site_history, decision:) }

    context "when the decision is 'granted'" do
      let(:decision) { "granted" }

      it "returns 'granted'" do
        expect(site_history.decision_type).to eq("granted")
      end
    end

    context "when the decision is 'not_required'" do
      let(:decision) { "not_required" }

      it "returns 'not_required'" do
        expect(site_history.decision_type).to eq("not_required")
      end
    end

    context "when the decision is 'refused'" do
      let(:decision) { "refused" }

      it "returns 'refused'" do
        expect(site_history.decision_type).to eq("refused")
      end
    end

    context "when the decision is not a standard value" do
      let(:decision) { "Application Permitted" }

      it "returns 'other'" do
        expect(site_history.decision_type).to eq("other")
      end
    end
  end

  describe "#other_decision?" do
    let(:site_history) { build(:site_history, decision:) }

    context "when the decision is 'granted'" do
      let(:decision) { "granted" }

      it "returns false" do
        expect(site_history.other_decision?).to eq(false)
      end
    end

    context "when the decision is 'not_required'" do
      let(:decision) { "not_required" }

      it "returns false" do
        expect(site_history.other_decision?).to eq(false)
      end
    end

    context "when the decision is 'refused'" do
      let(:decision) { "refused" }

      it "returns false" do
        expect(site_history.other_decision?).to eq(false)
      end
    end

    context "when the decision is not a standard value" do
      let(:decision) { "Application Permitted" }

      it "returns true" do
        expect(site_history.other_decision?).to eq(true)
      end
    end
  end
end
