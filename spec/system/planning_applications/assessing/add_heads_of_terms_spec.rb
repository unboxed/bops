# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add heads of terms" do
  let(:default_local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, name: "PlanX", local_authority: default_local_authority) }
  let!(:assessor) { create(:user, :assessor, local_authority: default_local_authority) }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority: default_local_authority, api_user:)
  end

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.id}"
    click_link "Check and assess"
  end

  context "when planning application is planning permission" do
    it "you can send heads of terms" do
      click_link "Send heads of terms"

      expect(page).to have_content("Heads of terms")

      attach_file("Upload heads of terms", "spec/fixtures/images/proposed-floorplan.png")

      click_button "Submit"

      expect(page).to have_content "Heads of terms successfully created and sent to applicant"

      expect(page).to have_list_item_for(
        "Send heads of terms",
        with: "In progress"
      )

      click_link "Send heads of terms"

      expect(page).to have_content "Applicant has not responded yet"
    end

    it "shows errors" do
      click_link "Send heads of terms"

      click_button "Submit"

      expect(page).to have_content "Document can't be blank"
    end

    it "I can cancel my request" do
      click_link "Send heads of terms"

      attach_file("Upload heads of terms", "spec/fixtures/images/proposed-floorplan.png")

      click_button "Submit"

      expect(page).to have_list_item_for(
        "Send heads of terms",
        with: "In progress"
      )

      click_link "Send heads of terms"

      click_link "Cancel request"

      fill_in "Explain to the applicant why this request is being cancelled", with: "Sent wrong file"

      click_button "Confirm cancellation"

      expect(page).to have_content "Heads of terms successfully cancelled"
    end

    it "I can see the applicant's response" do
      create(:heads_of_terms_validation_request, planning_application:, approved: true, state: "closed")

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"

      expect(page).to have_list_item_for(
        "Send heads of terms",
        with: "Valid"
      )

      click_link "Send heads of terms"

      expect(page).to have_content "The heads of terms have been approved by the applicant"
    end
  end

  context "when planning application is not planning permission" do
    xit "you cannot send heads of terms" do
      type = create(:application_type)
      planning_application.update(application_type: type)

      visit "/planning_applications/#{planning_application.id}"
      click_link "Check and assess"

      expect(page).not_to have_content("Send heads of terms")
    end
  end
end
