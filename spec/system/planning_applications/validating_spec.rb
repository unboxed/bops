# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "validate and invalidate" do
  it "can be validated" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link planning_application.reference
    click_link "Validate documents"

    choose "Yes"

    fill_in "Day", with: "03"
    fill_in "Month", with: "12"
    fill_in "Year", with: "2021"

    click_button "Save"

    expect(page).to have_content("Application is ready for assessment")

    planning_application.reload
    expect(planning_application.status).to eq("in_assessment")
    expect(planning_application.documents_validated_at).to eq(Date.new(2021, 12, 3))

    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails + 1)

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Application validated")
    expect(page).to have_text(assessor.name)
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end

  it "can be invalidated" do
    delivered_emails = ActionMailer::Base.deliveries.count
    click_link planning_application.reference
    click_link "Validate documents"

    choose "No"

    click_button "Save"

    expect(page).to have_content("Application has been invalidated")

    planning_application.reload
    expect(planning_application.status).to eq("invalidated")

    expect(ActionMailer::Base.deliveries.count).to eq(delivered_emails)

    click_button "Key application dates"
    click_link "Activity log"

    expect(page).to have_text("Application invalidated")
    expect(page).to have_text(assessor.name)
    expect(page).to have_text(Audit.last.created_at.strftime("%d-%m-%Y %H:%M"))
  end
end

RSpec.describe "Planning Application Assessment", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  let!(:planning_application) do
    create :planning_application, :not_started, local_authority: @default_local_authority
  end

  let!(:document) do
    create :document, :with_file, :with_tags, planning_application: planning_application
  end

  before do
    sign_in assessor
    visit root_path
  end

  context "Checking documents from Not Started status" do
    include_examples "validate and invalidate"
  end

  context "Checking documents from Invalidated status" do
    let!(:planning_application) do
      create :planning_application, :invalidated, local_authority: @default_local_authority
    end

    include_examples "validate and invalidate"
  end

  context "Planning application does not transition when expected inputs are not sent" do
    it "shows error when no radio button is selected" do
      click_link planning_application.reference
      click_link "Validate documents"

      click_button "Save"

      planning_application.reload
      expect(page).to have_content("Please select one of the below options")
      expect(planning_application.status).to eql("not_started")
    end

    it "shows error if invalid date is sent" do
      click_link planning_application.reference
      click_link "Validate documents"

      choose "Yes"

      fill_in "Day", with: "3"
      fill_in "Month", with: "&&£$£$"
      fill_in "Year", with: "2022"

      click_button "Save"

      planning_application.reload
      # This is stopped by HTML 5 validations, which are hard to test the UI for.
      expect(planning_application.status).to eql("not_started")
    end

    it "shows error if date is empty" do
      click_link planning_application.reference
      click_link "Validate documents"

      choose "Yes"

      fill_in "Day", with: ""
      fill_in "Month", with: ""
      fill_in "Year", with: ""

      click_button "Save"

      planning_application.reload
      expect(planning_application.status).to eql("not_started")
      expect(page).to have_content("Please enter a valid date")
    end
  end

  context "Planning application is in determined state" do
    let!(:planning_application) do
      create :planning_application, :determined, local_authority: @default_local_authority
    end

    it "does not show validate form" do
      visit planning_application_documents_path(planning_application)

      expect(page).not_to have_content("Save")
    end
  end
end
