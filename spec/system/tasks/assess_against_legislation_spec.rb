# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assess against legislation", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:api_user) { create(:api_user, :validation_requests_ro, local_authority:) }
  let(:assessor) { create(:user, :assessor, local_authority:) }
  let(:reference) { planning_application.reference }

  let!(:schedule) { create(:policy_schedule, number: 2, name: "Permitted development rights") }
  let!(:part1) { create(:policy_part, name: "Development within the curtilage of a dwellinghouse", number: 1, policy_schedule: schedule) }
  let!(:part2) { create(:policy_part, name: "Minor operations", number: 2, policy_schedule: schedule) }
  let!(:policy_classA) { create(:policy_class, section: "A", name: "enlargement, improvement or other alteration of a dwellinghouse", policy_part: part1) }
  let!(:policy_classB) { create(:policy_class, section: "B", name: "additions etc to the roof of a dwellinghouse", policy_part: part1) }
  let!(:policy_sectionA1a) { create(:policy_section, section: "1a", description: "description for section A.1a", policy_class: policy_classA) }
  let!(:policy_sectionB1b) { create(:policy_section, section: "1b", description: "description for section B.1b", policy_class: policy_classB) }

  let(:case_record) { planning_application.case_record }
  let(:slug) { "check-and-assess/assess-against-legislation/assess-against-legislation" }
  let(:task) { case_record.find_task_by_slug_path!("check-and-assess/assess-against-legislation/assess-against-legislation") }

  shared_examples "assessing an LDC application" do
    before do
      sign_in(assessor)
      visit "/planning_applications/#{reference}"
    end

    it "requires the application to be checked if it is development" do
      click_link "Check and assess"
      click_link "Assess against legislation"

      expect(page).to have_selector("h1", text: "Assess against legislation")
      expect(page).to have_content("Proposal not checked if it is development")
    end

    it "tells the officer that assessment is not required when it is not development" do
      click_link "Check and assess"
      click_link "Check if proposal is development"

      expect(page).to have_selector("h1", text: "Check if proposal is development")

      within_fieldset "Is this proposal 'development'" do
        choose "No"
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Section 55 development was successfully updated")

      click_link "Assess against legislation"

      expect(page).to have_selector("h1", text: "Assess against legislation")
      expect(page).to have_content("Not required as application has been classed as not being development")
    end

    it "policy classes can be added, removed and assessed" do
      expect(task.reload).not_to be_completed

      click_link "Check and assess"

      click_link "Check if proposal is development"

      expect(page).to have_selector("h1", text: "Check if proposal is development")

      within_fieldset "Is this proposal 'development'" do
        choose "Yes"
      end

      click_button "Save and mark as complete"
      expect(page).to have_content("Section 55 development was successfully updated")

      click_link "Assess against legislation"

      expect(page).to have_selector("h1", text: "Assess against legislation")

      click_button "Add new assessment area"

      within_fieldset "Select the part" do
        choose "Part 1"
      end

      click_button "Continue"

      within_fieldset "Add classes to assess" do
        check "Class A"
      end

      click_button "Continue"
      expect(page).to have_content("Policy class was successfully added")

      within "#assessment-areas" do
        expect(page).to have_content("Part 1, Class A")
        expect(page).to have_content("To be determined")

        click_link "Remove"
      end

      expect(page).to have_content("Policy class has been removed")

      click_button "Add new assessment area"

      within_fieldset "Select the part" do
        choose "Part 1"
      end

      click_button "Continue"

      within_fieldset "Add classes to assess" do
        check "Class B"
      end

      click_button "Continue"
      expect(page).to have_content("Policy class was successfully added")

      within "#assessment-areas" do
        expect(page).to have_content("Part 1, Class B")
        expect(page).to have_content("To be determined")

        click_link "Assess"
      end

      expect(page).to have_selector("h1", text: "Assess – Part 1, Class B")

      choose "Complies"
      fill_in "Add comment", with: "This is a comment"

      click_button "Save assessment"
      expect(page).to have_content("Assessment for policy class successfully saved")

      within "#assessment-areas" do
        expect(page).to have_content("Part 1, Class B")
        expect(page).to have_content("Complies")

        click_link "Assess"
      end

      expect(page).to have_selector("h1", text: "Assess – Part 1, Class B")
      expect(page).to have_content("This is a comment")

      click_link "Back"
      expect(page).to have_selector("h1", text: "Assess against legislation")

      click_button "Save and mark as complete"
      expect(page).to have_content("Assessment against legislation successfully saved")

      expect(task.reload).to be_completed
    end
  end

  context "when the application is not an LDC application" do
    let(:planning_application) do
      create(
        :planning_application,
        :planning_permission,
        :in_assessment,
        :with_constraints,
        local_authority:,
        api_user:
      )
    end

    before do
      sign_in(assessor)
      visit "/planning_applications/#{reference}"
    end

    it "doesn't have a 'Assess against legislation' task" do
      click_link "Check and assess"

      expect(page).not_to have_link("Assess against legislation")
    end
  end

  context "when the application is a LDCP application" do
    let(:planning_application) do
      create(
        :planning_application,
        :ldc_proposed,
        :in_assessment,
        :with_constraints,
        local_authority:,
        api_user:
      )
    end

    it_behaves_like "assessing an LDC application"
  end

  context "when the application is a LDCE application" do
    let(:planning_application) do
      create(
        :planning_application,
        :ldc_existing,
        :in_assessment,
        :with_constraints,
        local_authority:,
        api_user:
      )
    end

    it_behaves_like "assessing an LDC application"
  end
end
