# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let(:local_authority) {
    create :local_authority,
    name: "Cookie authority",
    signatory_name: "Mr. Biscuit",
    signatory_job_title: "Lord of BiscuitTown",
    enquiries_paragraph: "reach us on postcode SW50",
    email_address: "biscuit@somuchbiscuit.com"
    }
  let!(:assessor) { create :user, :assessor, name: "Lorrine Krajcik", local_authority: local_authority }
  let!(:reviewer) { create :user, :reviewer, name: "Harley Dicki", local_authority: local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started,
            :lawfulness_certificate,
            local_authority: local_authority
  end

  before do
    sign_in assessor
    visit root_path
  end

  context "Cancelling from Not Started status" do
    scenario "Withdraw from Not Started" do
      click_link planning_application.reference
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Withdrawn by applicant"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      within("#closed") do
        expect(page).to have_content("Withdrawn")
        click_link planning_application.reference
      end

      expect(page).not_to have_content("Cancel application")
    end

    scenario "Return from Not Started" do
      click_link planning_application.reference
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Returned as invalid"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      within("#closed") do
        expect(page).to have_content("Returned")
        click_link planning_application.reference
      end

      expect(page).not_to have_content("Cancel application")
    end
  end

  context "Cancelling from In Assessment" do
    before do
      planning_application.start!
    end

    scenario "Withdraw from In Assessment" do
      click_link planning_application.reference
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Withdrawn by applicant"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      within("#closed") do
        expect(page).to have_content("Withdrawn")
        click_link planning_application.reference
      end

      expect(page).not_to have_content("Cancel application")
    end

    scenario "Return from In Assessment" do
      click_link planning_application.reference
      expect(planning_application.status).to eql("in_assessment")
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Returned as invalid"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      within("#closed") do
        expect(page).to have_content("Returned")
        click_link planning_application.reference
      end

      expect(page).not_to have_content("Cancel application")
    end
  end

  context "Cancelling from Invalidated" do
    before do
      planning_application.invalidate!
    end

    scenario "Withdraw from Invalidated" do
      click_link planning_application.reference
      expect(planning_application.status).to eql("invalidated")
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Withdrawn by applicant"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      within("#closed") do
        expect(page).to have_content("Withdrawn")
        click_link planning_application.reference
      end

      expect(page).not_to have_content("Cancel application")
    end

    scenario "Return from Invalidated" do
      click_link planning_application.reference
      expect(planning_application.status).to eql("invalidated")
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Returned as invalid"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      within("#closed") do
        expect(page).to have_content("Returned")
        click_link planning_application.reference
      end

      expect(page).not_to have_content("Cancel application")
    end
  end

  context "Cancelling from Awaiting Determination" do
    before do
      planning_application.start!
      planning_application.assess!
    end

    scenario "Withdraw from Awaiting Determination" do
      click_link planning_application.reference
      expect(planning_application.status).to eql("awaiting_determination")
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Withdrawn by applicant"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      within("#closed") do
        expect(page).to have_content("Withdrawn")
        click_link planning_application.reference
      end

      expect(page).not_to have_content("Cancel application")
    end

    scenario "Return from Awaiting Determination" do
      click_link planning_application.reference
      expect(planning_application.status).to eql("awaiting_determination")
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Returned as invalid"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      within("#closed") do
        expect(page).to have_content("Returned")
        click_link planning_application.reference
      end

      expect(page).not_to have_content("Cancel application")
    end
  end
end
