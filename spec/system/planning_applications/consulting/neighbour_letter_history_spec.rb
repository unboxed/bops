# frozen_string_literal: true

require "rails_helper"
require "faraday"

def toggle_accordion(text)
  find_all("span", text:).first.click
end

RSpec.describe "View history of letters to neighbours", type: :system do
  let(:api_user) { create(:api_user, name: "PlanX") }
  let(:local_authority) { create(:local_authority, :default) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let!(:application_type) { create(:application_type, :prior_approval) }

  let(:planning_application) do
    create(:planning_application,
      :from_planx_prior_approval,
      :with_boundary_geojson,
      :published,
      application_type:,
      local_authority:,
      api_user:,
      agent_email: "agent@example.com",
      applicant_email: "applicant@example.com")
  end

  let(:consultation) { planning_application.consultation }

  let(:neighbours) { create_list(:neighbour, 5, consultation:) }
  let(:batch) { consultation.neighbour_letter_batches.new }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("BOPS_ENVIRONMENT", "development").and_return("production")

    travel_to(2.weeks.ago) do
      consultation.start_deadline
    end

    neighbours.each_with_index do |neighbour, notify_id|
      neighbour_letter = create(:neighbour_letter, neighbour:, status: "submitted", notify_id:, batch:)
      neighbour.touch(:last_letter_sent_at)
      stub_get_notify_status(notify_id: neighbour_letter.notify_id)
    end

    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}/consultation"
  end

  it "is accessible" do
    toggle_accordion "Consultation audit log"
    click_on "View copy of neighbour letters"
    expect(page).to have_content "Copy of neighbour letters"
  end

  it "contains an accordion" do
    toggle_accordion "Consultation audit log"
    click_on "View copy of neighbour letters"
    expect(page).to have_content "Neighbour letter 1"
  end

  it "contains a list of letters in the accordion" do
    toggle_accordion "Consultation audit log"
    click_on "View copy of neighbour letters"
    click_button "Neighbour letter 1"

    neighbours.each do |neighbour|
      expect(page).to have_content(neighbour.address)
    end
  end

  it "can access a pdf containing the text of the letter", pending: "grover seems weird in tests" do
    toggle_accordion "Consultation audit log"
    click_on "View copy of neighbour letters"
    click_button "Neighbour letter 1"

    click_on "Download letter"
    expect(page.html.lines.first).to match(/^%PDF-1.\d$/)
  end

  it "can access a csv containing the neighbours and the dates they were contacted" do
    toggle_accordion "Consultation audit log"
    click_on "View copy of neighbour letters"

    click_on "Download all as CSV"
    expect(page.html.lines.first.encode("utf-8")).to eq(%("address","batch","date"\n))
    neighbours.each do |neighbour|
      expect(page).to have_content(neighbour.address)
    end
  end
end
