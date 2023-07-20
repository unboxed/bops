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

  context "when there's a consultation" do
    let(:consultation) { create(:consultation) }

    before do
      consultation.start_deadline
      planning_application.consultation = consultation
      planning_application.save!

      render_inline(component)
    end

    it "renders consultation deadline" do
      expect(page).to have_content("Consultation deadline:\n    14 August 2023")
    end
  end

  context "when there's no consultation" do
    it "does not render consultation deadline" do
      expect(page).not_to have_content("Consultation deadline:")
    end
  end

  context "when the consultation has not started" do
    let(:consultation) { create(:consultation, start_date: nil) }

    before do
      planning_application.consultation = consultation
      planning_application.save!

      render_inline(component)
    end

    it "renders consultation deadline as not started" do
      expect(page).to have_content("Consultation deadline:\n    Not yet started")
    end
  end
end
