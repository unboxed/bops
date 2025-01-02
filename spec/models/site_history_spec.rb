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

    it "validates the date is in the past" do
      expect(build(:site_history, date: Date.current)).to be_invalid
    end
  end

  describe "normalizations" do
    describe "#decision" do
      it "normalizes 'Application Granted' to 'granted'" do
        expect(build(:site_history, decision: "Application Granted")).to have_attributes(decision: "granted")
      end

      it "normalizes 'Application Refused' to 'refused'" do
        expect(build(:site_history, decision: "Application Refused")).to have_attributes(decision: "refused")
      end

      it "normalizes 'Not Required' to 'not_required'" do
        expect(build(:site_history, decision: "Not Required")).to have_attributes(decision: "not_required")
      end
    end
  end
end
