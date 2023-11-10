# frozen_string_literal: true

require "rails_helper"

RSpec.describe "View consultee responses", js: true do
  let(:api_user) { create(:api_user, name: "PlanX") }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:application_type) { create(:application_type, :planning_permission) }
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) {
    create(:planning_application, :from_planx_prior_approval,
      application_type:, local_authority:, api_user:)
  }

  let(:consultation) { planning_application.consultation }
  let(:consultee) { create(:consultee, :consulted, consultation:) }
  let!(:consultee_response) { create(:consultee_response, consultee:) }

  before do
    planning_application.consultation.update(end_date: 2.days.ago)

    sign_in assessor
    visit planning_application_path(planning_application)
    click_link "Consultees, neighbours and publicity"
  end

  it "exists" do
    expect(consultee.responses).not_to be_empty
  end

  it "is listed on the page" do
    click_on "View consultee responses"
    click_on "View all responses"

    expect(page).to have_text(consultee.name)
  end

  it "can be redacted and published" do
    click_on "View consultee responses"
    click_on "View all responses"
    click_on "Redact and publish"

    expect(page).to have_text(consultee_response.response)

    fill_in("Redacted comment", with: "hello world")
    click_on "Save and publish"

    expect(consultee_response.reload.redacted_response).to eq("hello world")
  end
end
