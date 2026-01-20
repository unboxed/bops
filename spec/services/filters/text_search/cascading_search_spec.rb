# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filters::TextSearch::CascadingSearch do
  let(:local_authority) { create(:local_authority, :default) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }
  let(:filter) { described_class.new }

  let!(:app_with_reference) do
    create(:planning_application, local_authority:, description: "Unrelated content")
  end

  let!(:app_with_postcode) do
    create(:planning_application, local_authority:, postcode: "SW1A 1AA", description: "Another unrelated")
  end

  let!(:app_with_address) do
    create(:planning_application, local_authority:, address_1: "123 High Street", description: "Yet another")
  end

  let!(:app_with_description) do
    create(:planning_application, local_authority:, description: "Build a chimney stack")
  end

  describe "#applicable?" do
    it "returns false when query is blank" do
      expect(filter.applicable?({submit: "search"})).to be false
    end

    it "returns false when submit is blank" do
      expect(filter.applicable?({query: "test"})).to be false
    end

    it "returns true when both query and submit are present" do
      expect(filter.applicable?({query: "test", submit: "search"})).to be true
    end
  end

  describe "#apply" do
    context "when query matches reference" do
      let(:params) { {query: app_with_reference.reference, submit: "search"} }

      it "returns matching application" do
        result = filter.apply(scope, params)
        expect(result).to include(app_with_reference)
      end

      it "stops at first match (reference)" do
        # Reference search should succeed, so description search won't run
        allow(BopsCore::Filters::TextSearch::DescriptionSearch).to receive(:apply)
        filter.apply(scope, params)
        expect(BopsCore::Filters::TextSearch::DescriptionSearch).not_to have_received(:apply)
      end
    end

    context "when query matches postcode" do
      let(:params) { {query: "SW1A 1AA", submit: "search"} }

      it "returns matching application" do
        result = filter.apply(scope, params)
        expect(result).to include(app_with_postcode)
      end
    end

    context "when query matches address" do
      let(:params) { {query: "High Street", submit: "search"} }

      it "returns matching application" do
        result = filter.apply(scope, params)
        expect(result).to include(app_with_address)
      end
    end

    context "when query matches description" do
      let(:params) { {query: "chimney stack", submit: "search"} }

      it "returns matching application" do
        result = filter.apply(scope, params)
        expect(result).to include(app_with_description)
      end
    end

    context "when query has no matches" do
      let(:params) { {query: "zzxxyyww99887766", submit: "search"} }

      it "returns empty result" do
        result = filter.apply(scope, params)
        expect(result).to be_empty
      end
    end

    context "when query causes SQL error" do
      let(:params) { {query: "test & | !", submit: "search"} }

      it "returns empty result without raising" do
        expect { filter.apply(scope, params) }.not_to raise_error
      end
    end
  end
end
