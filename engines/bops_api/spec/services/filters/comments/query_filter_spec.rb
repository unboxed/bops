# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsApi::Filters::Comments::QueryFilter do
  let(:local_authority) { create(:local_authority) }
  let(:planning_application) { create(:planning_application, local_authority:) }
  let(:consultation) { create(:consultation, planning_application:) }
  let(:neighbour) { create(:neighbour, consultation:) }
  let(:filter) { described_class.new }

  describe "#applicable?" do
    it "returns true when query param is present" do
      expect(filter.applicable?({query: "test"})).to be true
    end

    it "returns false when query param is blank" do
      expect(filter.applicable?({})).to be false
    end

    it "returns false when query param is empty string" do
      expect(filter.applicable?({query: ""})).to be false
    end
  end

  describe "#apply" do
    let!(:response1) do
      create(:neighbour_response,
        neighbour:,
        redacted_response: "I support this development proposal")
    end
    let!(:response2) do
      create(:neighbour_response,
        neighbour:,
        redacted_response: "I object to this planning application")
    end
    let!(:response3) do
      create(:neighbour_response,
        neighbour:,
        redacted_response: "The proposal looks fine to me")
    end

    let(:scope) { NeighbourResponse.all }

    it "filters by query matching redacted_response" do
      result = filter.apply(scope, {query: "support"})

      expect(result).to include(response1)
      expect(result).not_to include(response2, response3)
    end

    it "is case insensitive" do
      result = filter.apply(scope, {query: "SUPPORT"})

      expect(result).to include(response1)
    end

    it "matches partial text" do
      result = filter.apply(scope, {query: "proposal"})

      expect(result).to include(response1, response3)
      expect(result).not_to include(response2)
    end

    it "returns empty when no matches" do
      result = filter.apply(scope, {query: "nonexistent"})

      expect(result).to be_empty
    end
  end
end
