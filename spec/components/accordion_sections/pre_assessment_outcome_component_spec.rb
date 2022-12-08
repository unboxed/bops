# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::PreAssessmentOutcomeComponent, type: :component do
  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  context "when there is no result" do
    let(:planning_application) do
      create(
        :planning_application,
        result_flag: nil,
        result_heading: nil,
        result_description: nil,
        result_override: nil
      )
    end

    it "renders 'not assessed' message" do
      render_inline(component)

      expect(page).to have_content(
        "The application was not assessed on submission"
      )
    end
  end

  context "when result is present" do
    let(:planning_application) do
      create(
        :planning_application,
        result_flag: "test flag",
        result_heading: "test heading",
        result_description: "test description",
        result_override: result_override,
        proposal_details: proposal_details,
        updated_address_or_boundary_geojson: updated_address_or_boundary_geojson,
        feedback: feedback
      )
    end

    let(:result_override) { nil }
    let(:proposal_details) { [].to_json }
    let(:updated_address_or_boundary_geojson) { false }
    let(:feedback) { {} }

    before { render_inline(component) }

    it "renders result flag" do
      expect(page).to have_content("test flag")
    end

    it "renders result heading" do
      expect(page).to have_content("test heading")
    end

    it "renders result description" do
      expect(page).to have_content("test description")
    end

    context "when 'updated_address_or_boundary_geojson' is true" do
      let(:updated_address_or_boundary_geojson) { true }

      it "renders warning text" do
        expect(page).to have_content(
          "This application has been updated. The result may no longer be accurate."
        )
      end
    end

    context "when 'result' feedback is present" do
      let(:feedback) do
        { result: "feedback" }
      end

      it "renders feedback" do
        expect(page).to have_content("feedback")
      end

      it "renders warning message" do
        expect(page).to have_content(
          "The applicant or agent believes this result is inaccurate."
        )
      end
    end

    context "when result override is present" do
      let(:result_override) { "test override" }

      it "renders result override" do
        expect(page).to have_content("test override")
      end
    end

    context "when there are proposal details" do
      let(:proposal_details) do
        [
          {
            question: "test question",
            responses: [
              {
                value: "test response",
                metadata: { flags: ["test flag"] }
              }
            ]
          }
        ].to_json
      end

      it "renders question" do
        expect(page).to have_content("test question")
      end

      it "renders response" do
        expect(page).to have_content("test response")
      end
    end
  end
end
