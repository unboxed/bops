# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Assessing against policies and guidance", type: :system, js: true do
  let!(:local_authority) { create(:local_authority, :default) }
  let!(:api_user) { create(:api_user, local_authority:) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }
  let(:consideration_set) { planning_application.consideration_set }

  let!(:planning_application) do
    create(:planning_application, :planning_permission, :in_assessment, local_authority:, api_user:, decision: "granted")
  end

  before do
    create(:decision, :householder_granted)
    create(:decision, :householder_refused)
    create(:local_authority_policy_area, local_authority:, description: "Design")
    create(:local_authority_policy_area, local_authority:, description: "Environment")
    create(:local_authority_policy_reference, local_authority:, code: "PP100", description: "Wall materials")
    create(:local_authority_policy_reference, local_authority:, code: "PP101", description: "Roofing materials")
    create(:local_authority_policy_reference, local_authority:, code: "PP200", description: "Flood risk")
    create(:local_authority_policy_guidance, local_authority:, description: "Design Guidance")
    create(:local_authority_policy_guidance, local_authority:, description: "Environmental Guidance")

    sign_in assessor

    visit "/planning_applications/#{planning_application.id}"
    click_link "Check and assess"
  end

  it "I see errors when required fields are missing" do
    within "#assess-against-policies-and-guidance" do
      expect(page).to have_content("Not started")
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_selector("h1", text: "Assess against policies and guidance")
    expect(page).to have_content("No considerations added yet")
    expect(page).to have_selector("details[open]")

    click_button "Add consideration"

    within "div[role=alert]" do
      expect(page).to have_content("Enter the policy area of this consideration")
      expect(page).to have_content("Enter at least one existing policy reference for this consideration")
      expect(page).to have_content("Enter the assessment of this consideration")
      expect(page).to have_content("Enter the conclusion for this consideration")
    end
  end

  it "I can add considerations" do
    within "#assess-against-policies-and-guidance" do
      expect(page).to have_content("Not started")
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_selector("h1", text: "Assess against policies and guidance")
    expect(page).to have_content("No considerations added yet")
    expect(page).to have_selector("details[open]")

    fill_in "Enter policy area", with: "Design"
    pick "Design", from: "#consideration-policy-area-field"

    expect(page).to have_selector("div.govuk-hint", text: "Start typing to find an existing policy reference")
    fill_in "Enter policy references", with: "Wall"
    pick "PP100 - Wall materials", from: "#policyReferencesAutoComplete"

    fill_in "Enter policy references", with: "Roofing"
    pick "PP101 - Roofing materials", from: "#policyReferencesAutoComplete"

    expect(page).to have_selector("div.govuk-hint", text: "Start typing to find existing policy guidance")
    fill_in "Enter policy guidance", with: "Design"
    pick "Design Guidance", from: "#policyGuidanceAutoComplete"

    fill_in "Enter assessment", with: "Uses red brick with grey slates"
    fill_in "Enter conclusion", with: "Complies with design guidance policies"

    click_button "Add consideration"

    expect(page).to have_content("Consideration was successfully added")
    expect(page).to have_no_selector("details[open]")

    toggle "Add new consideration"

    fill_in "Enter policy area", with: "Environment"
    pick "Environment", from: "#consideration-policy-area-field"

    fill_in "Enter policy references", with: "Flood"
    pick "PP200 - Flood risk", from: "#policyReferencesAutoComplete"

    fill_in "Enter policy guidance", with: "Environmental"
    pick "Environmental Guidance", from: "#policyGuidanceAutoComplete"

    fill_in "Enter assessment", with: "Property is outside of flood risk zones"
    fill_in "Enter conclusion", with: "Complies with environmental guidance policies"

    click_button "Add consideration"

    expect(page).to have_content("Consideration was successfully added")
    expect(page).to have_no_selector("details[open]")

    within "main ol" do
      within "li:nth-of-type(1)" do
        expect(page).to have_selector("h2", text: "Design")

        expect(page).to have_selector("dd", text: "PP100: Wall materials; PP101: Roofing materials", visible: false)
        expect(page).to have_selector("dd", text: "Design Guidance", visible: false)
        expect(page).to have_selector("dd", text: "Uses red brick with grey slates", visible: false)
        expect(page).to have_selector("dd", text: "Complies with design guidance policies", visible: false)

        click_button "Show more"

        expect(page).to have_selector("dd", text: "PP100: Wall materials; PP101: Roofing materials")
        expect(page).to have_selector("dd", text: "Design Guidance")
        expect(page).to have_selector("dd", text: "Uses red brick with grey slates")
        expect(page).to have_selector("dd", text: "Complies with design guidance policies")
      end

      within "li:nth-of-type(2)" do
        expect(page).to have_selector("h2", text: "Environment")

        expect(page).to have_selector("dd", text: "PP200: Flood risk", visible: false)
        expect(page).to have_selector("dd", text: "Environmental Guidance", visible: false)
        expect(page).to have_selector("dd", text: "Property is outside of flood risk zones", visible: false)
        expect(page).to have_selector("dd", text: "Complies with environmental guidance policies", visible: false)

        click_button "Show more"

        expect(page).to have_selector("dd", text: "PP200: Flood risk")
        expect(page).to have_selector("dd", text: "Environmental Guidance")
        expect(page).to have_selector("dd", text: "Property is outside of flood risk zones")
        expect(page).to have_selector("dd", text: "Complies with environmental guidance policies")
      end
    end

    click_button "Save and mark as complete"

    within("#assess-against-policies-and-guidance") do
      expect(page).to have_content("Completed")
    end
  end

  it "I can save progress and come back later" do
    within "#assess-against-policies-and-guidance" do
      expect(page).to have_content("Not started")
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_selector("h1", text: "Assess against policies and guidance")
    expect(page).to have_content("No considerations added yet")
    expect(page).to have_selector("details[open]")

    fill_in "Enter policy area", with: "Design"
    pick "Design", from: "#consideration-policy-area-field"

    fill_in "Enter policy references", with: "Wall"
    pick "PP100 - Wall materials", from: "#policyReferencesAutoComplete"

    fill_in "Enter policy references", with: "Roofing"
    pick "PP101 - Roofing materials", from: "#policyReferencesAutoComplete"

    fill_in "Enter policy guidance", with: "Design"
    pick "Design Guidance", from: "#policyGuidanceAutoComplete"

    fill_in "Enter assessment", with: "Uses red brick with grey slates"
    fill_in "Enter conclusion", with: "Complies with design guidance policies"

    click_button "Add consideration"

    expect(page).to have_content("Consideration was successfully added")
    expect(page).to have_no_selector("details[open]")

    click_button "Save and come back later"

    within("#assess-against-policies-and-guidance") do
      expect(page).to have_content("In progress")
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_selector("h1", text: "Assess against policies and guidance")

    toggle "Add new consideration"

    fill_in "Enter policy area", with: "Environment"
    pick "Environment", from: "#consideration-policy-area-field"

    fill_in "Enter policy references", with: "Flood"
    pick "PP200 - Flood risk", from: "#policyReferencesAutoComplete"

    fill_in "Enter policy guidance", with: "Environmental"
    pick "Environmental Guidance", from: "#policyGuidanceAutoComplete"

    fill_in "Enter assessment", with: "Property is outside of flood risk zones"
    fill_in "Enter conclusion", with: "Complies with environmental guidance policies"

    click_button "Add consideration"

    expect(page).to have_content("Consideration was successfully added")
    expect(page).to have_no_selector("details[open]")

    within "main ol" do
      within "li:nth-of-type(1)" do
        expect(page).to have_selector("h2", text: "Design")
      end

      within "li:nth-of-type(2)" do
        expect(page).to have_selector("h2", text: "Environment")
      end
    end

    click_button "Save and mark as complete"

    within("#assess-against-policies-and-guidance") do
      expect(page).to have_content("Completed")
    end
  end

  it "I can edit considerations" do
    within "#assess-against-policies-and-guidance" do
      expect(page).to have_content("Not started")
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_selector("h1", text: "Assess against policies and guidance")
    expect(page).to have_content("No considerations added yet")
    expect(page).to have_selector("details[open]")

    fill_in "Enter policy area", with: "Design"
    pick "Design", from: "#consideration-policy-area-field"

    fill_in "Enter policy references", with: "Wall"
    pick "PP100 - Wall materials", from: "#policyReferencesAutoComplete"

    fill_in "Enter policy guidance", with: "Design"
    pick "Design Guidance", from: "#policyGuidanceAutoComplete"

    fill_in "Enter assessment", with: "Uses red brick"
    fill_in "Enter conclusion", with: "Complies with design guidance policies"

    click_button "Add consideration"

    expect(page).to have_content("Consideration was successfully added")
    expect(page).to have_no_selector("details[open]")

    within "main ol" do
      within "li:nth-of-type(1)" do
        click_link "Edit"
      end
    end

    expect(page).to have_selector("h1", text: "Edit consideration")

    fill_in "Enter policy references", with: "Roofing"
    pick "PP101 - Roofing materials", from: "#policyReferencesAutoComplete"
    fill_in "Enter assessment", with: "Uses red brick with grey slates"

    click_button "Save consideration"

    expect(page).to have_content("Consideration was successfully saved")
    expect(page).to have_no_selector("details[open]")

    within "main ol" do
      within "li:nth-of-type(1)" do
        expect(page).to have_selector("h2", text: "Design")

        expect(page).to have_selector("dd", text: "PP100: Wall materials; PP101: Roofing materials", visible: false)
        expect(page).to have_selector("dd", text: "Design Guidance", visible: false)
        expect(page).to have_selector("dd", text: "Uses red brick with grey slates", visible: false)
        expect(page).to have_selector("dd", text: "Complies with design guidance policies", visible: false)

        click_button "Show more"

        expect(page).to have_selector("dd", text: "PP100: Wall materials; PP101: Roofing materials")
        expect(page).to have_selector("dd", text: "Design Guidance")
        expect(page).to have_selector("dd", text: "Uses red brick with grey slates")
        expect(page).to have_selector("dd", text: "Complies with design guidance policies")
      end
    end
  end

  it "I can remove considerations" do
    create(:consideration, consideration_set:, policy_area: "Design")
    create(:consideration, consideration_set:, policy_area: "Environment")

    page.refresh

    within "#assess-against-policies-and-guidance" do
      expect(page).to have_content("In progress")
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_selector("h1", text: "Assess against policies and guidance")

    within "main ol" do
      within "li:nth-of-type(1)" do
        expect(page).to have_selector("h2", text: "Design")
      end

      within "li:nth-of-type(2)" do
        expect(page).to have_selector("h2", text: "Environment")

        accept_confirm do
          click_link "Remove"
        end
      end
    end

    expect(page).to have_content("Consideration was successfully removed")

    within "main ol" do
      expect(page).to have_selector("li", count: 1)

      within "li:nth-of-type(1)" do
        expect(page).to have_selector("h2", text: "Design")
      end
    end
  end

  it "I can reorder considerations" do
    create(:consideration, consideration_set:, policy_area: "Design")
    create(:consideration, consideration_set:, policy_area: "Environment")

    page.refresh

    within "#assess-against-policies-and-guidance" do
      expect(page).to have_content("In progress")
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_selector("h1", text: "Assess against policies and guidance")

    within "main ol" do
      within "li:nth-of-type(1)" do
        expect(page).to have_selector("span", text: "Consideration 1")
        expect(page).to have_selector("h2", text: "Design")
      end

      within "li:nth-of-type(2)" do
        expect(page).to have_selector("span", text: "Consideration 2")
        expect(page).to have_selector("h2", text: "Environment")
      end

      consideration_1 = find("li:nth-of-type(1)")
      consideration_2 = find("li:nth-of-type(2)")
      consideration_2.drag_to(consideration_1)

      within "li:nth-of-type(1)" do
        expect(page).to have_selector("span", text: "Consideration 1")
        expect(page).to have_selector("h2", text: "Environment")
      end

      within "li:nth-of-type(2)" do
        expect(page).to have_selector("span", text: "Consideration 2")
        expect(page).to have_selector("h2", text: "Design")
      end
    end

    click_button "Save and come back later"

    within("#assess-against-policies-and-guidance") do
      expect(page).to have_content("In progress")
      click_link "Assess against policies and guidance"
    end

    expect(page).to have_selector("h1", text: "Assess against policies and guidance")

    within "main ol" do
      within "li:nth-of-type(1)" do
        expect(page).to have_selector("span", text: "Consideration 1")
        expect(page).to have_selector("h2", text: "Environment")
      end

      within "li:nth-of-type(2)" do
        expect(page).to have_selector("span", text: "Consideration 2")
        expect(page).to have_selector("h2", text: "Design")
      end
    end
  end

  it "I can see considerations when making a draft recommendation" do
    create(:consideration, consideration_set:, policy_area: "Design")
    create(:consideration, consideration_set:, policy_area: "Environment")

    within "#make-draft-recommendation" do
      expect(page).to have_content("Not started")
      click_link "Make draft recommendation"
    end

    expect(page).to have_selector("h1", text: "Make draft recommendation")

    within "#considerations-section" do
      expect(page).to have_selector("h3", text: "Policies and guidance")
      expect(page).to have_selector("h4", text: "Design")
      expect(page).to have_selector("h4", text: "Environment")
      expect(page).to have_link("Edit assessment", href: "/planning_applications/#{planning_application.id}/assessment/considerations/edit")
    end

    within_fieldset "Does this planning application need to be decided by committee?" do
      choose "No"
    end

    within_fieldset "What is your recommendation?" do
      choose "Granted"
    end

    fill_in "State the reasons for your recommendation", with: "Complies with all policies under the local plan"
    fill_in "Provide supporting information for your manager", with: "It all looks tickety-boo"

    click_button "Save and mark as complete"

    within "#make-draft-recommendation" do
      expect(page).to have_content("Completed")
    end

    click_link "Review and submit recommendation"

    expect(page).to have_selector("h1", text: "Review and submit recommendation")
    expect(page).to have_selector("button", text: "Assessment report details")

    click_button "Assessment report details"

    within "#considerations-section" do
      expect(page).to have_selector("h3", text: "Policies and guidance")
      expect(page).to have_selector("h4", text: "Design")
      expect(page).to have_selector("h4", text: "Environment")
      expect(page).to have_link("Edit assessment", href: "/planning_applications/#{planning_application.id}/assessment/considerations/edit")
    end

    click_button "Submit recommendation"

    expect(page).to have_content("Recommendation was successfully submitted")
  end
end
