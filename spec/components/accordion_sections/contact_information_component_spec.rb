# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::ContactInformationComponent, type: :component do
  let(:component) do
    described_class.new(planning_application: planning_application)
  end

  before { render_inline(component) }

  context "when agent contact details are present" do
    let(:planning_application) do
      create(
        :planning_application,
        agent_first_name: "Alice",
        agent_last_name: "Smith",
        agent_phone: "01234123123",
        agent_email: "alice@example.com"
      )
    end

    it "renders agent name" do
      expect(page).to have_content("Alice Smith")
    end

    it "renders agent number" do
      expect(page).to have_content("01234123123")
    end

    it "renders agent email" do
      expect(page).to have_content("alice@example.com")
    end
  end

  context "when applicant contact details are present" do
    let(:planning_application) do
      create(
        :planning_application,
        applicant_first_name: "Belle",
        applicant_last_name: "Jones",
        applicant_phone: "01234123124",
        applicant_email: "belle@example.com"
      )
    end

    it "renders agent name" do
      expect(page).to have_content("Belle Jones")
    end

    it "renders agent number" do
      expect(page).to have_content("01234123124")
    end

    it "renders agent email" do
      expect(page).to have_content("belle@example.com")
    end
  end

  context "when user role is present" do
    let(:planning_application) do
      create(:planning_application, user_role: :proxy)
    end

    it "renders user role" do
      expect(page).to have_content("proxy")
    end
  end
end
