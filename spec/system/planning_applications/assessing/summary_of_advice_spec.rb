# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Summary of Advice", type: :system, capybara: true do
  let(:local_authority) { create(:local_authority, :default) }
  let!(:assessor) { create(:user, :assessor, local_authority:) }

  let(:planning_application) do
    create(:planning_application, :pre_application, :in_assessment, local_authority:)
  end
  let!(:consultee) { create(:consultee, consultation: planning_application.consultation) }

  let!(:consultee_response_approved) do
    create(:consultee_response, name: "Heritage Officer", summary_tag: "approved", response: "No objections.", received_at: 2.days.ago, consultee:)
  end

  let!(:consultee_response_objected) do
    create(:consultee_response, name: "Environmental Agency", summary_tag: "objected", response: "Significant flooding risks identified.", received_at: 3.days.ago, consultee:)
  end

  let!(:consideration_set) { create(:consideration_set, planning_application:) }

  before do
    sign_in assessor
    visit "/planning_applications/#{planning_application.reference}"
    click_link "Check and assess"
  end

  it "displays considerations, consultee and constraints tabs" do
    create(:consideration, :design_consideration, consideration_set:, summary_tag: "does_not_comply")
    click_link "Summary of advice"

    within(".govuk-tabs") do
      expect(page).to have_css("#considerations")
      expect(page).to have_css("#consultees")
      expect(page).to have_css("#constraints")
    end

    within "#considerations" do
      expect(page).to have_content("Design: Roof lights")
    end
  end

  context "when displaying the summary of advice" do
    it "shows the outcome based on considerations" do
      create(:consideration, consideration_set:, summary_tag: "does_not_comply")

      click_link "Summary of advice"
      expect(page).to have_content("Unlikely to be supported (recommended based on considerations)")
    end

    it "shows needs_changes when no does_not_comply exists" do
      create(:consideration, consideration_set:, summary_tag: "needs_changes")

      click_link "Summary of advice"
      expect(page).to have_content("Likely to be supported with changes (recommended based on considerations)")
    end

    it "shows complies when all considerations comply" do
      create(:consideration, consideration_set:, summary_tag: "complies")

      click_link "Summary of advice"
      expect(page).to have_content("Likely to be supported (recommended based on considerations)")
    end
  end

  context "when adding summary of advice" do
    it "allows adding a new summary of advice" do
      within("#assessment-information-tasks") do
        expect(page).to have_content("Not started")
        click_link "Summary of advice"
      end

      choose "Likely to be supported (recommended based on considerations)"
      fill_in "Enter summary of planning considerations and advice. This should summarise any changes the applicant needs to make before they make an application.", with: "This proposal complies with all planning regulations."
      click_button "Save and mark as complete"

      expect(page).to have_content("Summary of advice was successfully created.")
      within("#assessment-information-tasks") do
        expect(page).to have_content("Completed")
        click_link "Summary of advice"
      end
      expect(page).to have_content("This proposal complies with all planning regulations.")
      expect(page).to have_css(".govuk-notification-banner.bops-notification-banner--green")

      click_link "Edit summary of advice"
      fill_in "Enter summary of planning considerations and advice. This should summarise any changes the applicant needs to make before they make an application.", with: "Updated summary of advice."
      choose "Likely to be supported with changes"
      click_button "Save and mark as complete"

      expect(page).to have_content("Summary of advice was successfully updated")
      click_link "Summary of advice"
      expect(page).to have_css(".govuk-notification-banner.bops-notification-banner--orange")

      click_link "Edit summary of advice"
      choose "Unlikely to be supported"
      click_button "Save and mark as complete"
      click_link "Summary of advice"
      expect(page).to have_css(".govuk-notification-banner.bops-notification-banner--red")
    end

    it "shows validation errors when no summary tag is selected" do
      click_link "Summary of advice"
      click_button "Save and mark as complete"

      expect(page).to have_content("Summary tag can't be blank")
      expect(page).to have_content("Entry can't be blank")
    end
  end
end
