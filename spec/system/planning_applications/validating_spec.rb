# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let(:local_authority) do
    create :local_authority,
           name: "Cookie authority",
           signatory_name: "Mr. Biscuit",
           signatory_job_title: "Lord of BiscuitTown",
           enquiries_paragraph: "reach us on postcode SW50",
           email_address: "biscuit@somuchbiscuit.com"
  end
  let!(:assessor) { create :user, :assessor, name: "Lorrine Krajcik", local_authority: local_authority }
  let!(:reviewer) { create :user, :reviewer, name: "Harley Dicki", local_authority: local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started,
           :lawfulness_certificate,
           local_authority: local_authority
  end

  let!(:document) do
    create :document, :with_file, :proposed_tags,
           planning_application: planning_application
  end

  before do
    sign_in assessor
    visit root_path
  end

  context "Checking documents from Not Started status" do
    it "can be validated from Not Started" do
      click_link planning_application.reference
      click_link "Check the documents"

      expect(page).to have_content("Are the documents valid?")

      choose "Yes"

      fill_in "Day", with: "03"
      fill_in "Month", with: "12"
      fill_in "Year", with: "2021"

      click_button "Save"

      expect(page).to have_content("Application is ready for assessment")

      click_link "Home"

      click_link "In assessment"

      within("#under_assessment") do
        click_link planning_application.reference
      end

      expect(page).not_to have_link("Check documents")
    end

    it "can be invalidated from Not Started" do
      click_link planning_application.reference
      click_link "Check the documents"

      expect(page).to have_content("Are the documents valid?")

      choose "No"

      click_button "Save"

      expect(page).to have_content("Application has been invalidated")

      click_link "Home"

      within("#not_started_and_invalid") do
        expect(page).to have_content("invalid")
        click_link planning_application.reference
      end

      expect(page).to have_link("Read the proposal")
      expect(page).not_to have_button("Save")

      click_link "Check the documents"
      expect(page).to have_link("Upload documents")
    end
  end

  context "Checking documents from Invalidated status" do
    it "can be validated from Invalidated" do
      planning_application.invalidate

      click_link planning_application.reference
      click_link "Check the documents"

      expect(page).to have_content("Are the documents valid?")

      choose "Yes"

      fill_in "Day", with: ""
      fill_in "Month", with: ""
      fill_in "Year", with: ""

      click_button "Save"

      expect(page).to have_content("A validation date must be present")

      choose "Yes"

      fill_in "Day", with: "03"
      fill_in "Month", with: "12"
      fill_in "Year", with: "2021"

      click_button "Save"

      expect(page).to have_content("Application is ready for assessment")

      click_link "Home"

      click_link "In assessment"

      within("#under_assessment") do
        click_link planning_application.reference
      end

      expect(page).not_to have_link("Check documents")
    end

    it "does not thrown an error when invalidated from Invalidated" do
      planning_application.invalidate

      click_link planning_application.reference
      click_link "Check the documents"

      expect(page).to have_content("Are the documents valid?")

      choose "No"

      click_button "Save"

      expect(page).to have_content("Application has been invalidated")

      click_link "Home"

      within("#not_started_and_invalid") do
        expect(page).to have_content("invalid")
        click_link planning_application.reference
      end

      expect(page).to have_link("Read the proposal")
      expect(page).not_to have_button("Save")

      click_link "Check the documents"
      expect(page).to have_link("Upload documents")
    end
  end

  context "Planning application does not transition when expected inputs are not sent" do
    it "shows error when no radio button is selected" do
      click_link planning_application.reference
      click_link "Check the documents"

      click_button "Save"

      expect(page).to have_content("Please choose Yes or No")
    end

    it "remains in not_started status if incorrect date is sent" do
      click_link planning_application.reference
      click_link "Check the documents"

      expect(page).to have_content("Are the documents valid?")

      choose "Yes"

      fill_in "Day", with: "3"
      fill_in "Month", with: "&&£$£$"
      fill_in "Year", with: "2022"

      click_button "Save"

      expect(planning_application.status).to eql("not_started")
      expect(planning_application.documents_validated_at).to be(nil)

      click_link "Home"
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content("Not started")
    end

    it "remains in not_started status if prefilled date is overwritten" do
      click_link planning_application.reference
      click_link "Check the documents"

      expect(page).to have_content("Are the documents valid?")

      choose "Yes"

      fill_in "Day", with: ""
      fill_in "Month", with: ""
      fill_in "Year", with: ""

      click_button "Save"

      expect(page).to have_content("A validation date must be present")

      expect(planning_application.status).to eql("not_started")
      expect(planning_application.documents_validated_at).to be(nil)

      click_link "Home"
      expect(page).to have_content(planning_application.reference)
      expect(page).to have_content("Not started")
    end
  end

  context "Planning application does not show validate documents form when withdrawn or returned" do
    it "does not show validate form when in withdrawn status" do
      click_link planning_application.reference
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Withdrawn by applicant"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      click_link planning_application.reference

      expect(page).not_to have_content("Are the documents valid?")
    end

    it "does not show validate form when in returned status" do
      click_link planning_application.reference
      click_link "Cancel application"

      expect(page).to have_content("Why is this application being cancelled?")

      choose "Returned as invalid"

      fill_in "cancellation_comment", with: "This has been cancelled"

      click_button "Save"

      expect(page).to have_content("Application has been cancelled")

      click_link "Home"

      click_link "Closed"

      click_link planning_application.reference

      expect(page).not_to have_content("Are the documents valid?")
    end
  end
end
