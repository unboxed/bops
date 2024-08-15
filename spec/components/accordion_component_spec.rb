# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  before { render_inline(component) }

  context "when no specific sections are specified" do
    let(:component) do
      described_class.new(planning_application:)
    end

    it "renders application information section" do
      expect(page).to have_element("span", text: "Application information")
    end

    it "renders site map section" do
      expect(page).to have_element("span", text: "Site map")
    end

    it "renders constraints section" do
      expect(page).to have_element("span", text: "Constraints")
    end

    it "renders pre-assessment outcome section" do
      expect(page).to have_element("span", text: "Pre-assessment outcome")
    end

    it "renders proposal details section" do
      expect(page).to have_element("span", text: "Proposal details")
    end

    it "renders documents section" do
      expect(page).to have_element("span", text: "Documents")
    end
  end

  context "when specific sections are specified" do
    let(:component) do
      described_class.new(
        planning_application:,
        sections: %i[contact_information key_application_dates audit_log notes]
      )
    end

    it "renders contact information section" do
      expect(page).to have_element("span", text: "Contact information")
    end

    it "renders key application dates section" do
      expect(page).to have_element("span", text: "Key application dates")
    end

    it "renders audit log section" do
      expect(page).to have_element("span", text: "Audit log")
    end

    it "renders notes section" do
      expect(page).to have_element("span", text: "Notes")
    end
  end
end
