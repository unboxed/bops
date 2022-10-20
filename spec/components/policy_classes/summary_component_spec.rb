# frozen_string_literal: true

require "rails_helper"

RSpec.describe PolicyClasses::SummaryComponent, type: :component do
  let(:summary_component) do
    described_class.new(policy_class: policy_class)
  end

  describe "#policies_summary" do
    before do
      summary_component.instance_variable_set(
        :@virtual_path,
        "summary_component"
      )
    end

    let(:policy_class) { create(:policy_class, policies: [policy1, policy2]) }
    let(:policy1) { create(:policy, :complies) }

    context "when all policies comply" do
      let(:policy2) { create(:policy, :complies) }

      it "returns 'Complies'" do
        expect(summary_component.send(:policies_summary)).to eq("Complies")
      end
    end

    context "when a policy does not comply" do
      let(:policy2) { create(:policy, :does_not_comply) }

      it "returns 'Does not comply'" do
        expect(
          summary_component.send(:policies_summary)
        ).to eq(
          "Does not comply"
        )
      end
    end

    context "when a policy is to be determined" do
      let(:policy1) { create(:policy, :to_be_determined) }
      let(:policy2) { create(:policy, :does_not_comply) }

      it "returns 'To be determined'" do
        expect(
          summary_component.send(:policies_summary)
        ).to eq(
          "To be determined"
        )
      end
    end
  end
end
