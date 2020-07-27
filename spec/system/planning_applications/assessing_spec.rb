# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Planning Application Assessment", type: :system do
  let!(:planning_application) do
    create :planning_application,
            :lawfulness_certificate
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

  before do
    sign_in users(:assessor)
    visit root_path
  end

  scenario "Assessment completing and editing" do
    click_link planning_application.reference

    # Ensure we're starting from a fresh "checklist"
    expect(page).not_to have_css(".app-task-list__task-completed")

    # The second step is not yet a link
    expect(page).not_to have_link("Submit the recommendation")

    within(".govuk-grid-column-two-thirds.application") do
      first('.govuk-accordion').click_button('Open all')
      expect(page).not_to have_text("Lorrine Krajcik")
    end

    click_link "Assess the proposal"

    expect(page).to have_content("The property is a semi detached house")
    expect(page).to have_content("The project will not alter the internal floor area of the building")

    expect(page).to have_text("Lorrine Krajcik")

    choose "Yes"

    expect(page).to have_content("By selecting yes, you are saying that this proposal complies with the GDPO.")
    expect(page).to have_content("Please add any comments that you would like to share with your manager.")

    fill_in "comment_granted", with: "This has been granted"

    click_button "Save"

    # Expect the 'completed' label to be present for the evaluation step
    within(:assessment_step, "Assess the proposal") do
      expect(page).to have_completed_tag
    end

    click_link "Assess the proposal"

    # Expect the saved state to be shown in the form
    within(find("form.decision")) do
      expect(page.find_field("Yes")).to be_checked
      expect(page.find("#comment_granted")).to have_content("This has been granted")
    end

    choose "Yes"

    click_button "Save"

    # Expect the 'completed' label to still be present for the evaluation step
    within(:assessment_step, "Assess the proposal") do
      expect(page).to have_completed_tag
    end

    click_link "Submit the recommendation"

    expect(page).to have_content("Submit the recommendation")
    expect(page).to have_content("The following decision notice has been created based on your answers.")

    expect(page).to have_content("Certificate of lawfulness of proposed use or development: #{planning_application.reload.assessor_decision.status}")

    # Applicant
    expect(page).to have_content("#{planning_application.applicant.full_name}")
    expect(page).to have_content("TBD")
    # Application received
    expect(page).to have_content("#{planning_application.created_at.strftime("%d/%m/%Y")}")
    # Address, TODO: add a fixture test for this
    # Application number
    expect(page).to have_content("#{planning_application.reference}")

    expect(page).to have_content("Certificate of lawful development (proposed) for the construction of #{planning_application.description}")

    expect(page).to have_content("If you agree with the decision notice, please submit it to your manager. If your manager disagrees with your recommendation they will send it back to you to make changes.")

    click_button "Submit to manager"

    within(:assessment_step, "Submit the recommendation") do
      expect(page).to have_completed_tag
    end

    click_link "Home"

    # Check that the application is no longer in assessment
    click_link "In assessment"

    within("#in_assessment") do
      expect(page).not_to have_link planning_application.reference
    end

    # Check that the application is now in awaiting determination
    click_link "Awaiting manager's determination"

    within("#awaiting_determination") do
      click_link planning_application.reference
    end

    # TODO: Continue this spec until the assessor decision has been made and check that policy evaluations can no longer be made
  end

  scenario "Assessor is assigned to planning application" do
    table_rows = all(".govuk-table__row").map(&:text)

    table_rows.each do |row|
      expect(row).to include("Not started") if row.include? planning_application.reference
    end

    click_link planning_application.reference

    # Ensure officer name is not displayed on page when accordion is opened
    within(".govuk-grid-column-two-thirds.application") do
      first('.govuk-accordion').click_button('Open all')
      expect(page).to have_text("Not started")
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

  include_examples "assessor decision error message"
end
