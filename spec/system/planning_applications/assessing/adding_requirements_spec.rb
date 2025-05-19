# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Add requirements", type: :system, capybara: true do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority: local_authority) }
  let!(:requirement) { create(:local_authority_requirement, local_authority:, category: "drawings", description: "Floor plans – existing") }
  let!(:requirement2) { create(:local_authority_requirement, local_authority:, category: "supporting_documents", description: "Parking plan") }
  let!(:requirement3) { create(:local_authority_requirement, local_authority:, category: "evidence", description: "Design statement") }
  let!(:requirement4) { create(:local_authority_requirement, local_authority:, category: "other", description: "Other") }
  let!(:recommended_application_type) { create(:application_type, :householder) }
  let!(:application_type_requirement) { create(:application_type_requirement, local_authority_requirement: requirement, application_type: recommended_application_type) }

  let(:planning_application) do
    create(
      :planning_application,
      :in_assessment,
      :pre_application,
      local_authority: local_authority,
      recommended_application_type: recommended_application_type
    )
  end

  let(:reference) { planning_application.reference }

  before do
    sign_in assessor
    visit "/planning_applications/#{reference}"
    click_link("Check and assess")
    click_link("Check and add requirements")
  end

  context "when a pre-app has no requirements added" do
    it "displays the form to add requirements" do
      expect(page).to have_content("Check and add requirements")
      expect(page).to have_link("Evidence")
      expect(page).to have_link("Supporting documents")
      expect(page).to have_content("Floor plans – existing")
      expect(page).not_to have_element(".govuk-summary-card")
    end

    it "shows pre-configured application type requirements" do
      expect(page).to have_content("The recommended application type is: #{recommended_application_type.description}")
      expect(page).to have_content("Any pre-configured requirements for #{recommended_application_type.description} have been pre-selected.")
      expect(page).to have_field("Floor plans – existing", type: "checkbox", checked: true)
    end
  end

  describe "adding a list of requirements" do
    before do
      click_link("Drawings")
      uncheck "Floor plans – existing"
      click_link("Evidence")
      check "Design statement"
      click_link("Supporting documents")
      check "Parking plan"

      click_button "Add requirements"
    end

    it "generates the table of planning application requirements" do
      expect(page).to have_content("Requirements successfully added")

      within("#supporting_documents-card") do
        expect(page).to have_content("Parking plan")
        expect(page).not_to have_content("Floor plans – existing")
      end

      within("#drawings-card") do
        expect(page).not_to have_content("Floor plans – existing")
      end
    end

    it "disables requirements already added" do
      find("span", text: "Add another requirement").click
      click_link("Supporting documents")
      expect(page).to have_field("Parking plan", type: "checkbox", disabled: true)
    end

    it "allows me to add further requirements" do
      toggle "Add another requirement"

      click_link("Drawings")
      check "Floor plans – existing"

      click_button "Add requirements"
      expect(page).to have_current_path("/planning_applications/#{reference}/assessment/requirements")
      expect(page).to have_content("Requirements successfully added")

      within("#drawings-card") do
        expect(page).to have_content("Floor plans – existing")
      end

      within("#other-card") do
        expect(page).to have_text("No requirements of this type selected")
      end
    end

    it "allows me to edit a requirement" do
      within("#evidence-card") do
        click_link("Edit")
      end

      expect(page).to have_selector("h1", text: "Edit requirement")
      expect(page).to have_content(requirement3.description)
      fill_in "Guidelines URL", with: "www.example.southwark.gov.uk"

      click_button "Save"

      expect(page).to have_content("Requirement successfully updated")
    end

    it "allows me to remove a requirement" do
      accept_alert(text: "Are you sure you want to remove this requirement?") do
        within("#evidence-card") do
          click_link("Remove")
        end
      end

      expect(page).to have_content("Requirement successfully removed")

      within("#evidence-card") do
        expect(page).not_to have_content(requirement3.description)
      end
    end
  end
end
