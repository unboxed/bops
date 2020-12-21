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
    create :planning_application,
            :lawfulness_certificate,
            local_authority: local_authority
  end

  let(:policy_consideration_1) do
    create :policy_consideration,
            policy_question: "The property is",
            applicant_answer: "a semi detached house"
  end

  let(:policy_consideration_2) do
    create :policy_consideration,
            policy_question: "The project will ___ the internal floor area of the building",
            applicant_answer: "not alter"
  end

  let!(:policy_evaluation) do
    create :policy_evaluation,
            planning_application: planning_application,
            policy_considerations: [policy_consideration_1, policy_consideration_2]
  end

  let!(:drawing) do
    create :drawing, :with_plan, :proposed_tags,
           planning_application: planning_application
  end

  before do
    sign_in assessor
    visit root_path
  end

  scenario "Assessment completing and editing" do
    click_link "In assessment"
    click_link planning_application.reference

    expect(page).to have_content("Make recommendation")
    expect(page).to have_link("Assess the proposal")

    # No steps have been completed
    expect(page).not_to have_content("Completed")

    # Cannot submit until preparation steps have been completed
    expect(page).not_to have_link("Submit the recommendation")

    # Application not yet associated with the assessor
    within(".govuk-grid-column-two-thirds.application") do
      first('.govuk-accordion').click_button('Open all')
      expect(page).not_to have_text("Lorrine Krajcik")
    end

    click_link "Assess the proposal"

    expect(page).to have_content("Please review the applicant's answers")

    # Application now associated with assessor
    expect(page).to have_text("Lorrine Krajcik")

    expect(page).to have_content("The property is a semi detached house")
    expect(page).to have_content("The project will not alter the internal floor area of the building")

    choose "Yes"

    fill_in "private_comment", with: "This is a private comment"

    click_button "Save"

    within(:assessment_step, "Assess the proposal") do
      expect(page).to have_content("Completed")
    end

    click_link "Assess the proposal"

    # Expect the saved state to be shown in the form
    within(find("form.decision")) do
      expect(page.find_field("Yes")).to be_checked
    end

    choose "Yes"

    expect(page).to have_content("This is a private comment")

    click_button "Save"

    # Expect the 'completed' label to still be present for the evaluation step
    within(:assessment_step, "Assess the proposal") do
      expect(page).to have_content("Completed")
    end

    # Unable to submit yet because not all steps are complete
    expect(page).not_to have_link("Submit the recommendation")

    click_link "Attach drawing numbers"

    fill_in("Drawing number:", with: "proposed_drawing_number_1, proposed_drawing_number_2")

    click_button "Save"

    within(:assessment_step, "Attach drawing numbers") do
      expect(page).to have_content("Completed")
    end

    click_link "Submit the recommendation"

    expect(page).to have_content("Submit the recommendation")
    expect(page).to have_content("The following decision notice has been created based on your answers.")

    expect(page).to have_content("Certificate of lawfulness of proposed use or development: #{planning_application.reload.assessor_decision.status}")

    # Applicant
    expect(page).to have_content("#{planning_application.applicant_first_name}")
    expect(page).to have_content("#{planning_application.applicant_last_name}")
    # Application received
    expect(page).to have_content("#{planning_application.created_at.strftime("%d/%m/%Y")}")
    # Address, TODO: add a fixture test for this
    # Application number
    expect(page).to have_content("#{planning_application.reference}")
    # Drawings
    expect(page).to have_content("proposed_drawing_number_1")
    expect(page).to have_content("proposed_drawing_number_2")
    expect(page).to have_content("Certificate of lawful development (proposed) for the construction of #{planning_application.description}")

    # Local authority specific fields
    expect(page).to have_content("Cookie authority")
    expect(page).to have_content("Mr. Biscuit")
    expect(page).to have_content("Lord of BiscuitTown")
    expect(page).to have_content("reach us on postcode SW50")
    expect(page).to have_content("biscuit@somuchbiscuit.com")

    click_button "Submit to manager"

    expect(page).to have_content("Determine the proposal")
    expect(page).to have_link("Review the recommendation")
    expect(page).to have_link("Publish the recommendation")

    within(:assessment_step, "Review the recommendation") do
      expect(page).not_to have_content("Completed")
    end

    expect(page).not_to have_link "Attach drawing numbers"

    click_link "Review the recommendation"
    click_link "Back"

    click_link "Publish the recommendation"
    click_link "Back"

    click_link "Home"

    # Check that the application is no longer in assessment
    click_link "In assessment"

    within("#under_assessment") do
      expect(page).not_to have_link planning_application.reference
    end

    # Check that the application is now in awaiting determination
    click_link "Awaiting manager's determination"

    within("#awaiting_determination") do
      click_link planning_application.reference
    end
  end

  scenario "Assessor is assigned to planning application" do
    table_rows = all(".govuk-table__row").map(&:text)

    click_link "In assessment"
    click_link planning_application.reference

    expect(page).to have_content("Make recommendation")
    expect(page).to have_link("Assess the proposal")
    expect(page).not_to have_link("Submit the recommendation")

    # Ensure officer name is not displayed on page when accordion is opened
    within(".govuk-grid-column-two-thirds.application") do
      first('.govuk-accordion').click_button('Open all')
    end

    click_link "Assess the proposal"

    # Ensure officer name is now displayed
    within(".govuk-grid-column-two-thirds.application") do
      expect(page).to have_text("Lorrine Krajcik")
    end

    click_link "Home"

    table_rows = all(".govuk-table__row").map(&:text)

    table_rows.each do |row|
      expect(row).to include("Lorrine Krajcik") if row.include? planning_application.reference
    end
  end

  context "when a drawing for publication is added after initial numbering" do
    # Simulate a completed decision step
    let!(:assessor_decision) { create :decision, :granted, user: assessor, planning_application: planning_application }

    # Number the current drawing
    before { drawing.update(numbers: "a number") }

    # Add a new drawing for publication which will require numbering
    let!(:new_drawing_to_number) { create :drawing, :with_plan, :proposed_tags, planning_application: planning_application }

    scenario "numbering needs to completed before submission" do
      click_link "In assessment"
      click_link planning_application.reference

      expect(page).not_to have_link "Submit the recommendation"

      within(:assessment_step, "Attach drawing numbers") do
        expect(page).to have_content("In Progress")
      end

      click_link("Attach drawing numbers")

      expect(page).to have_css(".thumbnail", count: 2)

      within(all(".thumbnail").last) do
        fill_in "Drawing number:", with: "new_drawing_number_1"
      end

      click_button "Save"

      within(:assessment_step, "Attach drawing numbers") do
        expect(page).to have_content("Completed")
      end

      click_link "Submit the recommendation"

      expect(page).to have_content "a number"
      expect(page).to have_content "new_drawing_number_1"
    end
  end

  scenario "shows the public_comment error message" do
    click_link "In assessment"
    within("#under_assessment") do
      click_link planning_application.reference
    end

    expect(page).not_to have_link("Submit the recommendation")

    click_link "Assess the proposal"

    choose "No"

    click_button "Save"

    within(".govuk-error-message") do
      expect(page).to have_content("Please provide which GDPO policy (or policies) have not been met.")
    end

    click_link "Home"

    expect(page).not_to have_content("Completed")
  end

  include_examples "assessor decision error message"
end
