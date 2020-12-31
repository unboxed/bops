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
    it "Validate from Not Started" do
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

    it "Invalidate from Not Started" do
      click_link planning_application.reference
      click_link "Check the documents"

      expect(page).to have_content("Are the documents valid?")

      choose "No"

      click_button "Save"

      expect(page).to have_content("Application has been invalidated")

      click_link "Home"

      within("#not_started_and_invalid") do
        expect(page).to have_content("invalidated")
        click_link planning_application.reference
      end

      expect(page).not_to have_link("Check documents")
    end
  end

  context "Planning application does not transition when expected inputs are not sent" do
    it "Error is shown when no radio button is selected" do
      click_link planning_application.reference
      click_link "Check the documents"

      click_button "Save"

      expect(page).to have_content("Please choose Yes or No")
    end

    it "Application remains in not_started status if incorrect date is sent" do
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
  end
end
