# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::ProposalDetailsComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  before { render_inline(component) }

  context "when 'updated_address_or_boundary_geojson' is true" do
    let(:planning_application) do
      create(:planning_application, updated_address_or_boundary_geojson: true)
    end

    it "renders warning message" do
      expect(page).to have_content(
        "This application has been updated. The proposal details may no longer be accurate. Please check all relevant details have been provided."
      )
    end
  end

  context "when 'find_property' feedback is present" do
    let(:planning_application) do
      create(:planning_application, feedback: { find_property: "feedback" })
    end

    it "renders warning message" do
      expect(page).to have_content(
        "The applicant or agent believes the information about the property is inaccurate."
      )
    end

    it "renders feedback" do
      expect(page).to have_content("feedback")
    end
  end

  context "when proposal details are present" do
    let(:proposal_details) do
      [
        {
          question: "test question",
          responses: [
            {
              value: "test response"
            }
          ]
        }
      ].to_json
    end

    let(:planning_application) do
      create(:planning_application, proposal_details: proposal_details)
    end

    it "renders proposal details" do
      expect(page).to have_content("test question")
    end
  end
end
