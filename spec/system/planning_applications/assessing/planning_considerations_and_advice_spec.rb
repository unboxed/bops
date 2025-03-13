# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add planning considerations and advice", type: :system, capybara: true do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let(:planning_application) do
    create(:planning_application, :pre_application, :in_assessment, local_authority: default_local_authority, consultation:)
  end
  let(:consultation) { create(:consultation) }
  let!(:consultee) { create(:consultee, consultation: planning_application.consultation) }

  let!(:consultee_response_approved) do
    create(:consultee_response, name: "Heritage Officer", summary_tag: "approved", response: "No objections.", received_at: 2.days.ago, consultee:)
  end

  let!(:consultee_response_objected) do
    create(:consultee_response, name: "Environmental Agency", summary_tag: "objected", response: "Significant flooding risks identified.", received_at: 3.days.ago, consultee:)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
    click_link "Planning considerations and advice"
  end

  it "displays consultee and constraints tabs" do
    within(".govuk-tabs") do
      expect(page).to have_css("#consultees")
      expect(page).to have_css("#constraints")
    end
  end

  it "displays consultee responses with status tags" do
    within ".govuk-grid-column-full" do
      expect(page).to have_content("Heritage Officer")
      expect(page).to have_content("No objections.")
      expect(page).to have_css(".govuk-tag.govuk-tag--green", text: "Approved")

      expect(page).to have_content("Environmental Agency")
      expect(page).to have_content("Significant flooding risks identified.")
      expect(page).to have_css(".govuk-tag.govuk-tag--red", text: "Objected")
    end
  end

  it "includes a link to view consultee responses" do
    expect(page).to have_link("View consultee responses", href: "/planning_applications/#{planning_application.reference}/consultee/responses", target: "_blank")
  end
end
