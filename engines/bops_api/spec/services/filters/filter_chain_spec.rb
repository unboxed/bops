# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::FilterChain do
  describe ".apply" do
    let(:scope) { PlanningApplication.all }
    let(:params) { {} }

    let(:filter1) do
      ->(s, _p) { s.where(status: "pending") }
    end

    let(:filter2) do
      ->(s, _p) { s.where(active: true) }
    end

    it "applies filters in sequence" do
      result = described_class.apply([filter1, filter2], scope, params)

      expect(result.to_sql).to include("status")
      expect(result.to_sql).to include("active")
    end

    it "works with no filters" do
      expect(described_class.apply([], scope, params)).to eq(scope)
    end

    it "works with a single filter" do
      result = described_class.apply([filter1], scope, params)

      expect(result.to_sql).to include("status")
    end
  end
end
