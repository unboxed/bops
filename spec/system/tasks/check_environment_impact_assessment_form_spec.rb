# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Check Environment Impact Assessment task", type: :system do
  let(:local_authority) { create(:local_authority, :default) }
  let(:planning_application) { create(:planning_application, :planning_permission, :not_started, local_authority:) }
  let(:task) { planning_application.case_record.find_task_by_slug_path!("check-and-validate/confirm-application-requirements/check-environment-impact-assessment") }

  let(:user) { create(:user, local_authority:) }

  let(:address_label) { "Enter an address where members of the public can view or request a copy of the Environmental Statement. Include name/number, street, town, postcode (optional)." }
  let(:email_label) { "Enter an email address where members of the public can request a copy of the Environmental Statement (optional)." }
  let(:fee_label) { "Enter the fee to obtain a hard copy of the Environmental Statement (optional)." }

  before do
    sign_in(user)
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and validate"
  end

  it "highlights the active task in the sidebar" do
    within ".bops-sidebar" do
      click_link "Check Environment Impact Assessment"
    end

    within ".bops-sidebar" do
      expect(page).to have_css(".bops-sidebar__task--active", text: "Check Environment Impact Assessment")
    end
  end

  it "displays the form with guidance link" do
    within ".bops-sidebar" do
      click_link "Check Environment Impact Assessment"
    end

    expect(page).to have_content("Is an Environmental Impact Assessment required?")
    expect(page).to have_link(
      "Check EIA guidance",
      href: "https://www.gov.uk/government/publications/environmental-impact-assessment-screening-checklist"
    )
  end

  context "when marking the EIA as required" do
    it "completes the task and saves the details" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      choose "Yes"
      fill_in email_label, with: "eia@example.com"
      fill_in address_label, with: "123 High Street, London"
      fill_in fee_label, with: "15"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed

      eia = planning_application.reload.environment_impact_assessment
      expect(eia.required).to be true
      expect(eia.email_address).to eq("eia@example.com")
      expect(eia.address).to eq("123 High Street, London")
      expect(eia.fee).to eq(15)
    end
  end

  context "when marking the EIA as not required" do
    it "completes the task" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      choose "No"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed

      eia = planning_application.reload.environment_impact_assessment
      expect(eia.required).to be false
      expect(eia.email_address).to be_nil
      expect(eia.address).to be_nil
      expect(eia.fee).to be_nil
    end
  end

  context "when submitting without selecting an option" do
    it "displays a validation error" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      click_button "Save and mark as complete"

      expect(page).to have_content("Select whether an Environment Impact Assessment is required.")
      expect(task.reload).not_to be_completed
    end
  end

  context "when selecting Yes with address but no fee" do
    it "displays a validation error" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      choose "Yes"
      fill_in address_label, with: "123 High Street"
      click_button "Save and mark as complete"

      expect(page).to have_content("Enter the fee to obtain a copy of the EIA")
      expect(task.reload).not_to be_completed
    end
  end

  context "when selecting Yes with fee but no address" do
    it "displays a validation error" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      choose "Yes"
      fill_in fee_label, with: "150"
      click_button "Save and mark as complete"

      expect(page).to have_content("Enter the address to view or request a copy of the EIA")
      expect(task.reload).not_to be_completed
    end
  end

  context "when changing from required to not required" do
    before do
      create(:environment_impact_assessment, planning_application:, required: true, address: "123 High Street", fee: 150, email_address: "eia@example.com")
      task.update!(status: :completed)
    end

    it "clears the details when switching to No" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      click_button "Edit"

      choose "No"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed

      eia = planning_application.reload.environment_impact_assessment
      expect(eia.required).to be false
      expect(eia.email_address).to be_nil
      expect(eia.address).to be_nil
      expect(eia.fee).to be_nil
    end
  end

  context "when changing from not required to required" do
    before do
      create(:environment_impact_assessment, planning_application:, required: false)
      task.update!(status: :completed)
    end

    it "allows setting details when switching to Yes" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      click_button "Edit"

      choose "Yes"
      fill_in address_label, with: "456 Main Road"
      fill_in fee_label, with: "200"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed

      eia = planning_application.reload.environment_impact_assessment
      expect(eia.required).to be true
      expect(eia.address).to eq("456 Main Road")
      expect(eia.fee).to eq(200)
    end
  end

  context "when submitting Yes without details" do
    it "completes successfully since address and fee are optional together" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      choose "Yes"
      click_button "Save and mark as complete"

      expect(task.reload).to be_completed

      eia = planning_application.reload.environment_impact_assessment
      expect(eia.required).to be true
    end
  end

  context "when validation fails" do
    it "retains the selected radio value after re-render" do
      within ".bops-sidebar" do
        click_link "Check Environment Impact Assessment"
      end

      choose "Yes"
      fill_in address_label, with: "123 Street"
      click_button "Save and mark as complete"

      expect(page).to have_content("Enter the fee to obtain a copy of the EIA")

      expect(page).to have_field("Yes", checked: true)
    end
  end
end
