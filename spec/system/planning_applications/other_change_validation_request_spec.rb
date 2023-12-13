# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Requesting other changes to a planning application" do
  let!(:default_local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :invalidated, local_authority: default_local_authority)
  end

  let!(:api_user) { create(:api_user, name: "Api Wizard") }

  before do
    travel_to Time.zone.local(2021, 1, 1)
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
  end

  it "displays the planning application address and reference" do
    click_link "Check and validate"
    click_link "Add another validation request"

    expect(page).to have_content(planning_application.full_address)
    expect(page).to have_content(planning_application.reference)
  end

  it "is possible to create a request for miscellaneous changes" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link "Check and validate"
    click_link "Add another validation request"

    expect(page).not_to have_content("Request other validation change (fee)")

    fill_in "Tell the applicant another reason why the application is invalid", with: "The wrong fee has been paid"
    fill_in "Explain to the applicant how the application can be made valid",
      with: "You need to pay £100, which is the correct fee"

    within(".govuk-button-group") do
      click_button "Send request"
    end

    click_link "Review validation requests"

    within(".validation-requests-table") do
      expect(page).to have_content("Other")
      expect(page).to have_content("The wrong fee has been paid")
      expect(page).to have_content("sent")
      expect(page).to have_link(
        "View and update",
        href: planning_application_validation_validation_request_path(planning_application, OtherChangeValidationRequest.last)
      )
    end

    click_link "Back"
    within("#invalid-items-count") do
      expect(page).to have_content("Invalid items 1")
    end
    within("#other-change-validation-tasks") do
      expect(page).to have_content("Invalid")
      expect(page).to have_link(
        "View other validation request #1",
        href: planning_application_validation_other_change_validation_request_path(planning_application, OtherChangeValidationRequest.last)
      )
    end

    click_link "View other validation request #1"
    expect(page).to have_content("View other request")
    expect(page).not_to have_content("View fee change request")
    expect(page).to have_link("Cancel request")
    expect(page).not_to have_link("Edit request")
    expect(page).not_to have_link("Delete request")

    click_link "Application"
    click_button "Audit log"
    click_link "View all audits"

    expect(page).to have_text("Sent: validation request (other validation#1)")
    expect(page).to have_text("The wrong fee has been paid")
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
    expect(ActionMailer::Base.deliveries.count).to eql(delivered_emails + 1)
  end

  it "only accepts a request that contains a summary and suggestion" do
    click_link "Check and validate"
    click_link "Add another validation request"

    fill_in "Tell the applicant another reason why the application is invalid", with: ""
    fill_in "Explain to the applicant how the application can be made valid", with: ""
    click_button "Send request"

    expect(page).to have_content("Provide a reason")
    expect(page).to have_content("Suggestion can't be blank")

    click_link("Back")

    expect(page).to have_current_path(
      "/planning_applications/#{planning_application.id}/validation/tasks"
    )
  end

  it "lists the current change requests and their statuses" do
    create(:other_change_validation_request, planning_application:, state: "open",
      created_at: 12.days.ago, notified_at: 12.days.ago, reason: "Missing information", suggestion: "Please provide more details about ownership")
    create(:other_change_validation_request, planning_application:, state: "closed",
      created_at: 12.days.ago, notified_at: 12.days.ago, reason: "Fees outstanding", suggestion: "Please pay the balance", response: "paid")

    click_link "Check and validate"
    click_link "Send validation decision"
    click_link "View existing requests"

    within(".validation-requests-table") do
      other_change_validation_request1 = OtherChangeValidationRequest.first

      within("#other_change_validation_request_#{other_change_validation_request1.id}") do
        expect(page).to have_content("Missing information")
        expect(page).to have_content("sent")
        expect(page).to have_link(
          "View and update",
          href: planning_application_validation_validation_request_path(planning_application, other_change_validation_request1)
        )
      end

      other_change_validation_request2 = OtherChangeValidationRequest.last

      within("#other_change_validation_request_#{other_change_validation_request2.id}") do
        expect(page).to have_content("Fees outstanding")
        expect(page).to have_content("Responded")
        expect(page).to have_link(
          "View and update",
          href: planning_application_validation_validation_request_path(planning_application, other_change_validation_request2)
        )
      end
    end
  end

  context "when invalidation updates other change validation request" do
    it "updates the notified_at date of an open request when application is invalidated" do
      new_planning_application = create(:planning_application, :not_started, local_authority: default_local_authority)
      request = create(:other_change_validation_request, planning_application: new_planning_application, state: "pending",
        created_at: 12.days.ago)

      visit "/planning_applications/#{new_planning_application.id}"
      click_link "Check and validate"
      click_link "Send validation decision"
      expect(request.notified_at).to be_nil

      click_button "Mark the application as invalid"

      expect(page).to have_content("Application has been invalidated")

      new_planning_application.reload
      expect(new_planning_application.status).to eq("invalidated")

      request.reload
      expect(request.notified_at).to be_a Time
    end
  end

  context "when there are fee item validation requests" do
    let!(:other_change_validation_request) do
      create(:other_change_validation_request, planning_application:)
    end
    let!(:fee_change_validation_request) do
      create(:fee_change_validation_request, planning_application:)
    end

    it "does not show in the other validation issues task list" do
      visit "/planning_applications/#{planning_application.id}/validation/tasks"

      within("#other-change-validation-tasks") do
        expect(page).to have_link(
          "View other validation request ##{other_change_validation_request.sequence}",
          href: planning_application_validation_other_change_validation_request_path(planning_application, other_change_validation_request)
        )
        expect(page).not_to have_link(
          "View other validation request ##{fee_change_validation_request.sequence}",
          href: planning_application_validation_validation_request_path(planning_application, fee_change_validation_request)
        )
      end
    end
  end

  context "when an officer adds a link in the suggestion/summary fields" do
    it "displays the link and link html as clickable" do
      click_link "Check and validate"
      click_link "Add another validation request"

      fill_in "Tell the applicant another reason why the application is invalid", with: "View info on https://www.bops.co.uk/info"
      fill_in "Explain to the applicant how the application can be made valid",
        with: "You need to pay the right amount, view <a href='https://www.bops.co.uk/payment'>Payment info</a>"

      within(".govuk-button-group") do
        click_button "Send request"
      end

      click_link("View other validation request #1")

      expect(page).to have_link(
        "https://www.bops.co.uk/info",
        href: "https://www.bops.co.uk/info"
      )

      expect(page).to have_link(
        "Payment info",
        href: "https://www.bops.co.uk/payment"
      )
    end
  end
end
