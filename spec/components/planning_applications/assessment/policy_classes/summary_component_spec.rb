# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanningApplications::Assessment::PolicyClasses::SummaryComponent, type: :component do
  let(:summary_component) do
    described_class.new(policy_class:)
  end

  describe "#policies_summary" do
    before do
      summary_component.instance_variable_set(
        :@virtual_path,
        "policy_classes.summary_component"
      )
    end

    let(:policy_class) { create(:policy_class, policies: [policy1, policy2]) }
    let(:policy1) { create(:policy, :complies) }

    context "when all policies comply" do
      let(:policy2) { create(:policy, :complies) }

      it "returns the right key" do
        expect(summary_component.send(:policies_summary_key)).to eq(".complies")
      end

      it "renders 'Complies'" do
        render_inline summary_component
        expect(page).to have_content("Complies")
      end
    end

    context "when a policy does not comply" do
      let(:policy2) { create(:policy, :does_not_comply) }

      it "returns the right key" do
        expect(
          summary_component.send(:policies_summary_key)
        ).to eq(".does_not_comply")
      end

      it "renders 'Does not comply'" do
        render_inline summary_component
        expect(page).to have_content("Does not comply")
      end
    end

    context "when a policy is to be determined" do
      let(:policy1) { create(:policy, :to_be_determined) }
      let(:policy2) { create(:policy, :does_not_comply) }

      it "returns the right key" do
        expect(
          summary_component.send(:policies_summary_key)
        ).to eq(".to_be_determined")
      end

      it "renders 'To be determined'" do
        render_inline summary_component
        expect(page).to have_content("To be determined")
      end
    end
  end
end
