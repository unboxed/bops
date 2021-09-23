# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let!(:assessor) { create :user, :assessor, local_authority: @default_local_authority }

  before do
    sign_in assessor
  end

  context "when the application hasn't been started" do
    let!(:planning_application) do
      create :planning_application, :not_started, local_authority: @default_local_authority
    end

    it "cannot be assessed against policies" do
      visit planning_application_path(planning_application)

      expect(page).not_to have_link "Add assessment area"
    end
  end

  context "when the application is in assessment" do
    let!(:planning_application) do
      create :planning_application, :in_assessment, local_authority: @default_local_authority
    end

    before do
      visit planning_application_path(planning_application)
    end

    def select_class(class_name)
      visit planning_application_path(planning_application)

      click_link "Add assessment area"

      choose "Part 1"
      click_button "Continue"

      check "Class #{class_name}"

      click_button "Add classes"
    end

    it "has a link to add an assessment area" do
      expect(page).to have_link "Add assessment area"
    end

    it "allows adding classes to assess against" do
      select_class "AA"
      select_class "C"

      expect(page).to have_current_path planning_application_path(planning_application), ignore_query: true

      expect(page).to have_text "Policy classes have been successfully added"

      within("#assess-policy-section") do
        expect(page).to have_link "Part 1, Class AA"
        expect(page).to have_link "Part 1, Class C"
      end
    end

    it "allows removing classes" do
      select_class "C"

      click_link "Part 1, Class C"

      click_button "Remove class from assessment"

      expect(page).to have_text "Policy class has been removed."

      expect(page).not_to have_link "Part 1, Class C"
    end

    it "defaults the policies to be determined" do
      select_class "AA"

      within("#assess-policy-section") do
        expect(page).to have_text "in assessment"
      end

      click_link "Part 1, Class AA"

      find_all("input:checked") do |node|
        expect(node.value).to eq "to_be_determined"
      end
    end

    describe "when the application is past assessment" do
      before do
        select_class "AA"

        planning_application.decision = "All good"
        planning_application.assess
        planning_application.determine

        visit planning_application_path(planning_application)
      end

      it "doesn't let the assessor add further classes" do
        within("#assess-policy-section") do
          expect(page).not_to have_text "Add assessment area"
        end
      end

      it "doesn't allow changing the policies status" do
        click_link "Part 1, Class AA"

        find_all("input[type='radio']") do |node|
          expect(node).to be_disabled
        end
      end

      it "doesn't allow deleting a class" do
        click_link "Part 1, Class A"

        expect(page).to have_button("Remove class from assessment", disabled: true)
      end
    end
  end
end
