# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionComponent, type: :component do
  let(:planning_application) { create(:planning_application) }

  before { render_inline(component) }

  context "when no specific sections are specified" do
    let(:component) do
      described_class.new(planning_application: planning_application)
    end

    it "renders application information section" do
      expect(page).to have_button("Application information")
    end

    it "renders site map section" do
      expect(page).to have_button("Site map")
    end

    it "renders constraints section" do
      expect(page).to have_button("Constraints")
    end

    it "renders pre-assessment outcome section" do
      expect(page).to have_button("Pre-assessment outcome")
    end

    it "renders proposal details section" do
      expect(page).to have_button("Proposal details")
    end

    it "renders consultation section" do
      expect(page).to have_button("Consultation")
    end

    it "renders documents section" do
      expect(page).to have_button("Documents")
    end
  end

  context "when specific sections are specified" do
    let(:component) do
      described_class.new(
        planning_application: planning_application,
        sections: %i[contact_information key_application_dates audit_log notes]
      )
    end

    it "renders contact information section" do
      expect(page).to have_button("Contact information")
    end

    it "renders key application dates section" do
      expect(page).to have_button("Key application dates")
    end

    it "renders audit log section" do
      expect(page).to have_button("Audit log")
    end

    it "renders notes section" do
      expect(page).to have_button("Notes")
    end
  end
end
