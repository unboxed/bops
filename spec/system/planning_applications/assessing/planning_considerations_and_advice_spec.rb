# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add planning considerations and advice", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(:planning_application, :pre_application, :in_assessment, local_authority:)
  end

  let(:reference) { planning_application.reference }
  let(:consideration_set) { planning_application.consideration_set }
  let(:considerations) { consideration_set.considerations }

  let!(:consultee) { create(:consultee, consultation: planning_application.consultation) }

  let!(:consultee_response_approved) do
    create(:consultee_response, name: "Heritage Officer", summary_tag: "approved", response: "No objections.", received_at: 2.days.ago, consultee:)
  end

  let!(:consultee_response_objected) do
    create(:consultee_response, name: "Environmental Agency", summary_tag: "objected", response: "Significant flooding risks identified.", received_at: 3.days.ago, consultee:)
  end

  before do
    sign_in assessor

    visit "/planning_applications/#{reference}"
    expect(page).to have_selector("h1", text: "Application")

    click_link "Check and assess"
    expect(page).to have_selector("h1", text: "Assess the application")

    within "main" do
      click_link "Planning considerations and advice"
    end
    expect(page).to have_selector("h1", text: "Add planning considerations and advice")
  end

  it "displays consultee and constraints tabs" do
    within(".govuk-tabs") do
      expect(page).to have_css("#consultees")
      expect(page).to have_css("#constraints")
    end
  end

  it "displays consultee responses with status tags" do
    within "#consultees" do
      expect(page).to have_content("Heritage Officer")
      expect(page).to have_content("No objections.")
      expect(page).to have_css(".govuk-tag.govuk-tag--green", text: "Approved")

      expect(page).to have_content("Environmental Agency")
      expect(page).to have_content("Significant flooding risks identified.")
      expect(page).to have_css(".govuk-tag.govuk-tag--red", text: "Objected")
    end
  end

  it "includes a link to view consultee responses" do
    expect(page).to have_link("View consultee responses", href: "/planning_applications/#{reference}/consultee/responses", target: "_blank")
  end

  it "allows progress to be saved" do
    click_button "Save and come back later"
    expect(page).to have_content("Assessment against local policies was successfully saved")

    within "#planning-considerations-and-advice" do
      expect(page).to have_link("Planning considerations and advice", href: "/planning_applications/#{reference}/assessment/consideration_guidances")
      expect(page).to have_selector("strong", text: "In progress")
    end
  end

  it "allows the task to be to be marked as complete" do
    click_button "Save and mark as complete"
    expect(page).to have_content("Assessment against local policies was successfully saved")

    within "#planning-considerations-and-advice" do
      expect(page).to have_link("Planning considerations and advice", href: "/planning_applications/#{reference}/assessment/consideration_guidances")
      expect(page).to have_selector("strong", text: "Completed")
    end
  end

  context "when adding considerations" do
    before do
      create(:local_authority_policy_area, local_authority:, description: "Transport")
      create(:local_authority_policy_area, local_authority:, description: "Design")
      create(:local_authority_policy_area, local_authority:, description: "Environment")
      create(:local_authority_policy_reference, local_authority:, code: "PP100", description: "Wall materials")
      create(:local_authority_policy_reference, local_authority:, code: "PP101", description: "Roofing materials")
      create(:local_authority_policy_reference, local_authority:, code: "PP200", description: "Flood risk")

      visit current_path
      expect(page).to have_selector("h1", text: "Add planning considerations and advice")
    end

    it "allows adding a new consideration" do
      expect(page).to have_selector("legend", text: "Add a new consideration")
      expect(page).to have_selector("details[open]")

      fill_in "Select policy area", with: "Transport"
      pick "Transport", from: "#consideration-policy-area-field"

      click_button "Add consideration"

      expect(page).to have_content("Consideration was successfully added")
      expect(page).to have_css(".govuk-summary-card__title", text: "Transport")
      expect(considerations.last.draft).to eq(true)

      toggle "Add advice"
      fill_in "Enter element of proposal", with: "A proposal"

      fill_in "Enter policy references", with: "Wall"
      pick "PP100 - Wall materials", from: "#policyReferencesAutoComplete"

      fill_in "Enter policy references", with: "Roofing"
      pick "PP101 - Roofing materials", from: "#policyReferencesAutoComplete"

      fill_in_rich_text_area "Advice", with: "This is what you need to do"

      choose "Complies"

      click_button "Save advice"
      expect(page).to have_content("Consideration was successfully added")
      expect(page).to have_content("A proposal")
      expect(page).to have_content("This is what you need to do")
      expect(page).to have_css(".govuk-tag.govuk-tag--green", text: "Complies")
      expect(considerations.last.draft).to eq(false)
    end

    it "shows validation errors when missing required fields" do
      click_button "Add consideration"

      expect(page).to have_content("Enter the policy area of this consideration")
    end

    it "shows a validation error when adding a duplicate policy area" do
      fill_in "Select policy area", with: "Transport"
      pick "Transport", from: "#consideration-policy-area-field"
      click_button "Add consideration"

      find("span", text: "Add a new consideration").click
      fill_in "Select policy area", with: "Transport"
      pick "Transport", from: "#consideration-policy-area-field"
      click_button "Add consideration"

      expect(page).to have_content("has already been taken")
    end

    it "show a validation error without required fields", :capybara do
      fill_in "Select policy area", with: "Transport"
      pick "Transport", from: "#consideration-policy-area-field"
      click_button "Add consideration"

      find("span", text: "Add advice").click
      click_button("Save advice")

      expect(page).to have_content("Enter assessment of this element of the proposal")
    end
  end

  context "when removing considerations" do
    let!(:consideration1) do
      create(:consideration, policy_area: "Design", consideration_set: planning_application.consideration_set)
    end
    let!(:consideration2) do
      create(:consideration, policy_area: "Design", consideration_set: planning_application.consideration_set)
    end

    before { visit current_path }

    it "allows removal of an existing consideration" do
      accept_confirm do
        within "#design" do
          within "#consideration_#{consideration2.id}" do
            click_link "Remove"
          end
        end
      end
      expect(page).to have_css(".govuk-summary-card__title", text: "Design")
      expect(page).to have_content("Consideration was successfully removed")

      accept_confirm do
        within "#design" do
          click_link "Remove"
        end
      end

      expect(page).to have_content("Consideration was successfully removed")
      expect(page).not_to have_css(".govuk-summary-card__title", text: "Design")
    end
  end

  context "when editing an existing consideration" do
    let!(:consideration) do
      create(:consideration, policy_area: "Transport", proposal: "The proposal", consideration_set: planning_application.consideration_set)
    end

    before do
      visit current_path
      within "#transport" do
        click_link "Edit"
      end
    end

    it "displays the edit form" do
      expect(page).to have_content("Edit planning considerations and advice")
      expect(find_field("Enter element of proposal").value).to eq("The proposal")
    end

    it "successfully updates the consideration" do
      fill_in "Enter element of proposal", with: "Updated proposal"
      choose "Needs changes"
      click_button "Save advice"

      expect(page).to have_content("Consideration was successfully updated")
      expect(page).to have_content("Updated proposal")
      expect(page).to have_css(".govuk-tag.govuk-tag--yellow", text: "Needs Changes")
    end

    it "shows validation errors when fields are missing" do
      fill_in "Enter element of proposal", with: ""
      click_button "Save advice"

      expect(page).to have_content("Enter element of the proposal being assessed")
    end
  end
end
