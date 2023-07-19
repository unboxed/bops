# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/PredicateMatcher
RSpec.describe PlanningApplicationHelper do
  describe "#filter_enabled_uniquely?" do
    it "returns true if this is the only filter enabled" do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new({ status: "not_started" }))
      expect(helper.filter_enabled_uniquely?(status: "not_started")).to be_truthy
    end

    it "returns false if this is not the only filter enabled" do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new({ status: "not_started", application_type: "prior_approval" }))
      expect(helper.filter_enabled_uniquely?(status: "not_started")).to be_falsy
    end

    it "returns false if no filters are enabled" do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new({}))
      expect(helper.filter_enabled_uniquely?(status: "not_started")).to be_falsy
    end
  end
end
# rubocop:enable RSpec/PredicateMatcher
