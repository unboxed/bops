# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccordionSections::KeyApplicationDatesComponent, type: :component do
  let(:planning_application) do
    create(
      :planning_application,
      :prior_approval,
      validated_at: Date.new(2022, 11, 12),
      received_at: Date.new(2022, 11, 11)
    )
  end
  let(:consultation) { planning_application.consultation }

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

  context "when planning application is validated" do
    let(:planning_application) do
      create(:planning_application)
    end

    it "renders validation date" do
      expect(page).to have_content("Valid from:\n    #{planning_application.valid_from.to_date.to_fs}\n")
    end
  end

  context "when there's a consultation" do
    before do
      consultation.start_deadline

      render_inline(component)
    end

    it "renders consultation start date" do
      expect(page).to have_content("Publicity started:\n    #{consultation.start_date.to_date.to_fs}\n")
    end

    it "renders consultation deadline" do
      expect(page).to have_content("Publicity deadline:\n    #{consultation.end_date.to_date.to_fs}\n")
    end
  end

  context "when there's no consultation" do
    let(:planning_application) do
      create(
        :planning_application,
        :ldc_proposed
      )
    end

    it "does not render consultation deadline" do
      expect(page).not_to have_content("Publicity deadline:")
    end
  end

  context "when the consultation has not started" do
    before do
      render_inline(component)
    end

    it "renders consultation deadline as not started" do
      expect(page).to have_content("Publicity deadline:\n    Not yet started")
    end
  end

  context "when the consultation has finished" do
    before do
      consultation.update!(start_date: 4.weeks.ago, end_date: 1.week.ago)

      render_inline(component)
    end

    it "renders publicity end date" do
      expect(page).to have_content("Publicity deadline:\n    #{consultation.end_date.to_date.to_fs}")
    end
  end
end
