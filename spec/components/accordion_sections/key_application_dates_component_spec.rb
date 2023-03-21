# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::KeyApplicationDatesComponent, type: :component do
  let(:planning_application) do
    create(
      :planning_application,
      validated_at: Date.new(2022, 11, 12),
      received_at: Date.new(2022, 11, 11)
    )
  end

  let(:component) do
    described_class.new(planning_application:)
  end

  before { render_inline(component) }

  it "renders received at date" do
    expect(page).to have_content("Application received:\n  11 November 2022")
  end

  it "renders target date" do
    expect(page).to have_content("Target date:\n  17 December 2022")
  end

  it "renders expiry date" do
    expect(page).to have_content("Expiry date:\n  7 January 2023")
  end

  context "when planning application is not validated" do
    let(:planning_application) do
      create(:planning_application, :not_started)
    end

    it "renders 'not yet valid' message" do
      expect(page).to have_content("Not yet valid")
    end
  end
end
