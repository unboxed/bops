# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Edit drawing", type: :system do
  let(:local_authority) { create :local_authority }
  let!(:planning_application) do
    create :planning_application,
           :lawfulness_certificate,
           local_authority: local_authority
  end
  let!(:drawing) { create :drawing, :with_plan, planning_application: planning_application }
  let(:assessor) { create :user, :assessor, local_authority: local_authority }
  let(:reviewer) { create :user, :reviewer, local_authority: local_authority }

  context "as a user who is not logged in" do
    scenario "User cannot see edit_numbers page" do
      visit edit_planning_application_drawing_path(planning_application, drawing)
      expect(page).to have_current_path(/sign_in/)
      expect(page).to have_content("You need to sign in or sign up before continuing.")
    end
  end

  context "as an assessor" do
    before do
      sign_in assessor
      visit planning_application_drawings_path(planning_application)
    end

    scenario "with valid data" do
      click_link "Edit"

      attach_file("Upload a file", "spec/fixtures/images/proposed-roofplan.pdf")
      fill_in 'Document number(s)', with: 'DOC001'

      check("floor plan - existing")
      check("section - proposed")

      click_button("Save and return")

      expect(page).to have_content("Document has been updated")
      expect(page).to have_content("proposed-roofplan.pdf")
      expect(page).to have_content('DOC001')
      expect(page).to have_css(".govuk-tag", text: "floor plan - existing")
      expect(page).to have_css(".govuk-tag", text: "section - proposed")
    end

    scenario "with wrong format document" do
      visit edit_planning_application_drawing_path(planning_application, drawing)

      attach_file("Upload a file", "spec/fixtures/images/bmp.bmp")

      click_button("Save and return")

      expect(page).to have_content("The selected file must be a PDF, JPG or PNG")
    end
  end
end
