# frozen_string_literal: true

require "rails_helper"

RSpec.describe BopsCore::Filters::TextSearch::ReferenceSearch do
  let(:local_authority) { create(:local_authority, :default) }
  let(:scope) { PlanningApplication.where(local_authority: local_authority) }

  let!(:matching_app) do
    create(:planning_application, local_authority:)
  end

  let!(:non_matching_app) do
    create(:planning_application, local_authority:)
  end

  describe ".apply" do
    context "with full reference" do
      it "returns applications matching the reference" do
        result = described_class.apply(scope, matching_app.reference)
        expect(result).to include(matching_app)
        expect(result).not_to include(non_matching_app)
      end
    end

    context "with partial reference" do
      it "returns applications containing the query in reference" do
        partial = matching_app.application_number.to_s.rjust(5, "0")
        result = described_class.apply(scope, partial)
        expect(result).to include(matching_app)
      end
    end

    context "with lowercase reference" do
      it "matches case-insensitively" do
        result = described_class.apply(scope, matching_app.reference.downcase)
        expect(result).to include(matching_app)
      end
    end

    context "with no matches" do
      it "returns empty result" do
        result = described_class.apply(scope, "NONEXISTENT-99999")
        expect(result).to be_empty
      end
    end
  end
end
