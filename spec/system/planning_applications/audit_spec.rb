# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auditing changes to a planning application" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority)
  end

  let!(:api_user) { create(:api_user) }

  before do
    create(:audit, planning_application_id: planning_application.id,
                   activity_type: "red_line_boundary_change_validation_request_received", activity_information: 1, audit_comment: { response: "rejected", reason: "The boundary was too small" }.to_json, api_user:)
    create(:audit, planning_application_id: planning_application.id,
                   activity_type: "other_change_validation_request_received", activity_information: 1, audit_comment: { response: "I have sent the fee" }.to_json, api_user:)
    create(:audit, planning_application_id: planning_application.id,
                   activity_type: "replacement_document_validation_request_received", activity_information: 1, audit_comment: "floor_plan.pdf", api_user:)

    sign_in assessor
    visit planning_application_path(planning_application)
    click_button "Audit log"
    click_link "View all audits"
  end

  it "displays the planning application address and reference" do
    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)
  end

  it "displays details of other change validation request in the audit log" do
    expect(page).to have_text("Received: request for change (other validation#1)")
    expect(page).to have_text("I have sent the fee")
    expect(page).to have_text("Applicant / Agent via BoPS applicants")
  end

  it "displays the details of a red line boundary request in the audit log" do
    expect(page).to have_text("Received: request for change (red line boundary#1)")
    expect(page).to have_text("The boundary was too small")
    expect(page).to have_text("rejected")
    expect(page).to have_text("Applicant / Agent via BoPS applicants")
  end

  it "displays the details of replacement boundary requests in the audit log" do
    expect(page).to have_text("Received: request for change (replacement document#1)")
    expect(page).to have_text("floor_plan.pdf")
    expect(page).to have_text("Applicant / Agent via BoPS applicants")
  end

  context "when red line boundary change request is auto closed" do
    let(:planning_application) do
      create(:planning_application, local_authority: default_local_authority)
    end

    let(:validation_request) do
      create(
        :red_line_boundary_change_validation_request,
        planning_application:
      )
    end

    before { validation_request.auto_close_request! }

    it "shows correct information with link to request" do
      visit(planning_application_audits_path(planning_application))

      expect(page).to have_row_for(
        "Auto-closed: validation request (red line boundary#1)",
        with: "Automated by the system"
      )

      click_link("Auto-closed: validation request (red line boundary#1)")

      expect(page).to have_current_path(
        planning_application_red_line_boundary_change_validation_request_path(
          planning_application,
          validation_request
        )
      )
    end
  end

  context "when description change request is auto closed" do
    let(:planning_application) do
      create(:planning_application, local_authority: default_local_authority)
    end

    let(:validation_request) do
      create(
        :description_change_validation_request,
        planning_application:
      )
    end

    before { validation_request.auto_close_request! }

    it "shows correct information with link to request" do
      visit(planning_application_audits_path(planning_application))

      expect(page).to have_row_for(
        "Auto-closed: validation request (description#1)",
        with: "Automated by the system"
      )

      click_link("Auto-closed: validation request (description#1)")

      expect(page).to have_current_path(
        planning_application_description_change_validation_request_path(
          planning_application,
          validation_request
        )
      )
    end
  end

  it "navigates back to the previous page I was on" do
    click_link "Back"
    expect(page).to have_current_path(planning_application_path(planning_application))
  end
end
